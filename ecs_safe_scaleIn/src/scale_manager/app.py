import json
import os
import time
import hashlib
import urllib.request
import boto3
import logging
from botocore.exceptions import ClientError, BotoCoreError
from typing import Dict, Any, Optional, Tuple

# Environment variables
TABLE_NAME = os.environ["TABLE_NAME"]
KAMAILIO_LAMBDA_ARN = os.environ["KAMAILIO_LAMBDA_ARN"]
DRAIN_TIMEOUT_SECONDS = int(os.environ.get("DRAIN_TIMEOUT_SECONDS", "14400"))
DRAIN_CONCURRENCY_LIMIT = int(os.environ.get("DRAIN_CONCURRENCY_LIMIT", "1"))
ASTERISK_HTTP_PORT = int(os.environ.get("ASTERISK_HTTP_PORT", "8080"))
ASTERISK_HTTP_SCHEME = os.environ.get("ASTERISK_HTTP_SCHEME", "http")
SCALER_FUNCTION_URL = os.environ["SCALER_FUNCTION_URL"]
SHARED_TOKEN = os.environ["SHARED_TOKEN"]
COOLDOWN_SECONDS = int(os.environ.get("COOLDOWN_SECONDS", "900"))  # 15 minutes
MAX_DRAINS_PER_HOUR = int(os.environ.get("MAX_DRAINS_PER_HOUR", "2"))

# AWS clients
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
ecs = boto3.client("ecs")
cloudwatch = boto3.client("cloudwatch")
appscaling = boto3.client("application-autoscaling")
lambda_client = boto3.client("lambda")

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _now() -> int:
    return int(time.time())


def _hash_id(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()[:16]


def _put_metric(metric_name: str, value: float, unit: str = "Count", dimensions: Optional[Dict] = None):
    """Put custom CloudWatch metric"""
    try:
        cloudwatch.put_metric_data(
            Namespace="ECS/SafeScaleIn",
            MetricData=[{
                "MetricName": metric_name,
                "Value": value,
                "Unit": unit,
                "Dimensions": dimensions or []
            }]
        )
    except Exception as e:
        logger.warning(f"Failed to put metric {metric_name}: {e}")


def _check_cooldown(service_arn: str) -> bool:
    """Check if service is in cooldown period"""
    try:
        # Check for recent drain activity
        cutoff_time = _now() - COOLDOWN_SECONDS
        resp = table.query(
            IndexName="service-state-index",
            KeyConditionExpression=boto3.dynamodb.conditions.Key("serviceArn").eq(service_arn),
            FilterExpression=boto3.dynamodb.conditions.Attr("startedAt").gte(cutoff_time)
        )
        recent_drains = len(resp.get("Items", []))
        return recent_drains > 0
    except Exception as e:
        logger.error(f"Failed to check cooldown for {service_arn}: {e}")
        return True  # Fail safe - assume in cooldown


def _check_hourly_limit(service_arn: str) -> bool:
    """Check if service has exceeded hourly drain limit"""
    try:
        hour_ago = _now() - 3600
        resp = table.query(
            IndexName="service-state-index",
            KeyConditionExpression=boto3.dynamodb.conditions.Key("serviceArn").eq(service_arn),
            FilterExpression=boto3.dynamodb.conditions.Attr("startedAt").gte(hour_ago)
        )
        hourly_drains = len(resp.get("Items", []))
        return hourly_drains >= MAX_DRAINS_PER_HOUR
    except Exception as e:
        logger.error(f"Failed to check hourly limit for {service_arn}: {e}")
        return True  # Fail safe - assume limit reached


def _get_running_tasks(cluster_arn: str, service_arn: str) -> list:
    task_arns = ecs.list_tasks(cluster=cluster_arn, serviceName=service_arn).get("taskArns", [])
    if not task_arns:
        return []
    desc = ecs.describe_tasks(cluster=cluster_arn, tasks=task_arns)
    return desc.get("tasks", [])


def _get_task_ip(task: dict) -> str:
    for att in task.get("attachments", []):
        if att.get("type") == "ElasticNetworkInterface":
            for d in att.get("details", []):
                if d.get("name") == "privateIPv4Address":
                    return d.get("value")
    return None


def _current_draining_count(service_arn: str) -> int:
    resp = table.query(
        IndexName="service-state-index",
        KeyConditionExpression=boto3.dynamodb.conditions.Key("serviceArn").eq(service_arn)
        & boto3.dynamodb.conditions.Key("state").eq("DRAINING")
    )
    return len(resp.get("Items", []))


def _pick_task(tasks: list) -> dict:
    # Strategy: pick the most recently started task that is not already draining
    candidates = []
    for t in tasks:
        if t.get("lastStatus") != "RUNNING":
            continue
        task_arn = t.get("taskArn")
        item = table.get_item(Key={"taskArn": task_arn}).get("Item")
        if item and item.get("state") == "DRAINING":
            continue
        candidates.append(t)
    if not candidates:
        return None
    candidates.sort(key=lambda x: x.get("startedAt", 0), reverse=True)
    return candidates[0]


def _invoke_kamailio(ip: str, drain_id: str) -> bool:
    """Invoke Kamailio Lambda with retry logic"""
    payload = {"action": "comment_out_ip", "target_ip": ip, "drainId": drain_id}
    max_retries = 3
    
    for attempt in range(max_retries):
        try:
            response = lambda_client.invoke(
                FunctionName=KAMAILIO_LAMBDA_ARN, 
                InvocationType="Event", 
                Payload=json.dumps(payload).encode("utf-8")
            )
            if response.get("StatusCode") == 202:
                logger.info(f"Kamailio invocation successful for {ip}, attempt {attempt + 1}")
                return True
        except Exception as e:
            logger.warning(f"Kamailio invocation failed for {ip}, attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
    
    logger.error(f"Kamailio invocation failed after {max_retries} attempts for {ip}")
    _put_metric("KamailioInvocationFailures", 1, dimensions=[{"Name": "TargetIP", "Value": ip}])
    return False


def _call_asterisk_start(ip: str, task_arn: str, drain_id: str) -> bool:
    """Call Asterisk drain start with retry logic"""
    url = f"{ASTERISK_HTTP_SCHEME}://{ip}:{ASTERISK_HTTP_PORT}/drain/start"
    body = json.dumps({
        "taskArn": task_arn,
        "drainId": drain_id,
        "maxDrainSeconds": DRAIN_TIMEOUT_SECONDS,
        "callbackUrl": SCALER_FUNCTION_URL,
        "token": SHARED_TOKEN,
    }).encode("utf-8")
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"}, method="POST")
            with urllib.request.urlopen(req, timeout=10) as r:
                if r.status in (200, 202):
                    logger.info(f"Asterisk drain start successful for {ip}, attempt {attempt + 1}")
                    return True
                else:
                    logger.warning(f"Asterisk drain start HTTP {r.status} for {ip}, attempt {attempt + 1}")
        except Exception as e:
            logger.warning(f"Asterisk drain start failed for {ip}, attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
    
    logger.error(f"Asterisk drain start failed after {max_retries} attempts for {ip}")
    _put_metric("AsteriskDrainStartFailures", 1, dimensions=[{"Name": "TargetIP", "Value": ip}])
    return False


def _extract_cluster_service_task_from_ecs_event(event) -> tuple[str, str, str]:
    """Extract cluster, service, and task from ECS protected scale-in attempt event"""
    detail = event.get("detail", {})
    cluster_arn = detail.get("clusterArn")
    task_arn = detail.get("taskArn")
    
    if not cluster_arn or not task_arn:
        raise ValueError("Missing clusterArn or taskArn in event")
    
    # 通过 DescribeTasks 获取服务信息
    response = ecs.describe_tasks(
        cluster=cluster_arn,
        tasks=[task_arn]
    )
    
    if not response.get("tasks"):
        raise ValueError("Task not found")
    
    task = response["tasks"][0]
    service_arn = task.get("serviceArn")
    
    if not service_arn:
        raise ValueError("Task not associated with a service")
    
    return cluster_arn, service_arn, task_arn


def handler(event, context):
    """Main handler with comprehensive error handling and logging"""
    try:
        logger.info(f"Processing ECS protected scale-in event: {json.dumps(event)}")
        
        # Extract cluster, service, and task from ECS event
        cluster_arn, service_arn, task_arn = _extract_cluster_service_task_from_ecs_event(event)
        logger.info(f"Target task: {task_arn}, service: {service_arn}, cluster: {cluster_arn}")
        
        # Check if task is already being drained
        existing_item = table.get_item(Key={"taskArn": task_arn}).get("Item")
        if existing_item and existing_item.get("state") == "DRAINING":
            logger.info(f"Task {task_arn} already being drained")
            return {"status": "skipped", "reason": "already_draining"}
        
        # Check cooldown period
        if _check_cooldown(service_arn):
            logger.info(f"Service {service_arn} in cooldown period")
            _put_metric("ScaleInSkipped", 1, dimensions=[{"Name": "Reason", "Value": "cooldown"}])
            return {"status": "skipped", "reason": "cooldown"}
        
        # Check hourly limit
        if _check_hourly_limit(service_arn):
            logger.info(f"Service {service_arn} exceeded hourly drain limit")
            _put_metric("ScaleInSkipped", 1, dimensions=[{"Name": "Reason", "Value": "hourly_limit"}])
            return {"status": "skipped", "reason": "hourly_limit"}
        
        # Check concurrent draining limit
        draining = _current_draining_count(service_arn)
        if draining >= DRAIN_CONCURRENCY_LIMIT:
            logger.info(f"Service {service_arn} at concurrent drain limit: {draining}")
            _put_metric("ScaleInSkipped", 1, dimensions=[{"Name": "Reason", "Value": "concurrency_limit"}])
            return {"status": "skipped", "reason": "concurrency_limit"}

        # Check min capacity
        svc = ecs.describe_services(cluster=cluster_arn, services=[service_arn])["services"][0]
        desired = svc.get("desiredCount", 0)
        parts = service_arn.split(":service/")[-1]
        cluster_name = parts.split("/")[0]
        service_name = parts.split("/")[1]
        resource_id = f"service/{cluster_name}/{service_name}"
        sts = appscaling.describe_scalable_targets(ServiceNamespace="ecs", ResourceIds=[resource_id]).get("ScalableTargets", [])
        min_capacity = sts[0]["MinCapacity"] if sts else 0
        if desired <= min_capacity:
            logger.info(f"Service {service_arn} at min capacity: {desired} <= {min_capacity}")
            _put_metric("ScaleInSkipped", 1, dimensions=[{"Name": "Reason", "Value": "at_min_capacity"}])
            return {"status": "skipped", "reason": "at_min_capacity", "desired": desired, "min": min_capacity}

        # Get task details and IP
        task_response = ecs.describe_tasks(cluster=cluster_arn, tasks=[task_arn])
        if not task_response.get("tasks"):
            logger.error(f"Task {task_arn} not found")
            _put_metric("ScaleInErrors", 1, dimensions=[{"Name": "Reason", "Value": "task_not_found"}])
            return {"status": "error", "reason": "task_not_found"}
        
        task = task_response["tasks"][0]
        ip = _get_task_ip(task)
        if not ip:
            logger.error(f"Could not extract IP for task {task_arn}")
            _put_metric("ScaleInErrors", 1, dimensions=[{"Name": "Reason", "Value": "no_ip"}])
            return {"status": "error", "reason": "no_ip"}

        drain_id = _hash_id(f"{task_arn}:{_now()//600}")  # bucketed 10min id
        logger.info(f"Processing task {task_arn} with IP {ip}, drainId: {drain_id}")

        # Transition Running -> DRAINING atomically
        try:
            table.update_item(
                Key={"taskArn": task_arn},
                UpdateExpression="SET #s = if_not_exists(#s, :running), serviceArn=:svc, drainId=:did, startedAt=:ts, clusterArn=:ca",
                ConditionExpression="attribute_not_exists(#s) OR #s = :running",
                ExpressionAttributeNames={"#s": "state"},
                ExpressionAttributeValues={
                    ":running": "RUNNING", 
                    ":svc": service_arn, 
                    ":did": drain_id, 
                    ":ts": _now(),
                    ":ca": cluster_arn
                },
            )
        except ClientError as e:
            if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
                logger.info(f"Task {task_arn} already being drained")
                return {"status": "skipped", "reason": "already_draining"}
            raise

        # Invoke Kamailio to remove IP from distribution
        if not _invoke_kamailio(ip, drain_id):
            logger.error(f"Failed to invoke Kamailio for {ip}, rolling back")
            # Rollback: mark task as RUNNING again
            table.update_item(
                Key={"taskArn": task_arn},
                UpdateExpression="SET #s = :running",
                ExpressionAttributeNames={"#s": "state"},
                ExpressionAttributeValues={":running": "RUNNING"},
            )
            return {"status": "error", "reason": "kamailio_failed"}

        # Call Asterisk to start drain
        if not _call_asterisk_start(ip, task_arn, drain_id):
            logger.error(f"Failed to start Asterisk drain for {ip}, rolling back")
            # Rollback: mark task as RUNNING again
            table.update_item(
                Key={"taskArn": task_arn},
                UpdateExpression="SET #s = :running",
                ExpressionAttributeNames={"#s": "state"},
                ExpressionAttributeValues={":running": "RUNNING"},
            )
            return {"status": "error", "reason": "asterisk_failed"}

        # Mark as DRAINING
        table.update_item(
            Key={"taskArn": task_arn},
            UpdateExpression="SET #s=:dr, lastIp=:ip",
            ExpressionAttributeNames={"#s": "state"},
            ExpressionAttributeValues={":dr": "DRAINING", ":ip": ip},
        )

        # Record metrics
        _put_metric("DrainStarted", 1, dimensions=[
            {"Name": "ServiceArn", "Value": service_arn},
            {"Name": "TaskArn", "Value": task_arn}
        ])
        _put_metric("DrainingCount", draining + 1, dimensions=[
            {"Name": "ServiceArn", "Value": service_arn}
        ])

        logger.info(f"Successfully started drain for task {task_arn}")
        return {"status": "started", "taskArn": task_arn, "ip": ip, "drainId": drain_id}

    except Exception as e:
        logger.error(f"Unexpected error in scale_manager: {e}", exc_info=True)
        _put_metric("ScaleInErrors", 1, dimensions=[{"Name": "Reason", "Value": "unexpected_error"}])
        raise


