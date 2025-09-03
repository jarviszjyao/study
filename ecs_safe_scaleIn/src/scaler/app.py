import json
import os
import time
import boto3
import logging
from botocore.exceptions import ClientError, BotoCoreError
from typing import Dict, Any, Optional

# Environment variables
TABLE_NAME = os.environ["TABLE_NAME"]
SHARED_TOKEN = os.environ["SHARED_TOKEN"]

# AWS clients
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
ecs = boto3.client("ecs")
appscaling = boto3.client("application-autoscaling")
cloudwatch = boto3.client("cloudwatch")

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _json(body, code=200):
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


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


def _auth(event):
    auth = event.get("headers", {}).get("authorization") or event.get("headers", {}).get("Authorization")
    if not auth or auth != f"Bearer {SHARED_TOKEN}":
        return False
    return True


def handler(event, context):
    """Main handler with comprehensive error handling and logging"""
    try:
        logger.info(f"Processing scaler callback: {json.dumps(event)}")
        
        # Authentication check
        if not _auth(event):
            logger.warning("Unauthorized scaler callback attempt")
            _put_metric("ScalerAuthFailures", 1)
            return _json({"message": "unauthorized"}, 401)

        # Parse request body
        body = json.loads(event.get("body") or "{}")
        task_arn = body.get("taskArn")
        drain_id = body.get("drainId")
        if not task_arn or not drain_id:
            logger.warning(f"Missing required fields: taskArn={task_arn}, drainId={drain_id}")
            return _json({"message": "taskArn and drainId required"}, 400)

        logger.info(f"Processing drain completion for task {task_arn}, drainId: {drain_id}")

        # Validate state and drainId
        item = table.get_item(Key={"taskArn": task_arn}).get("Item")
        if not item or item.get("state") != "DRAINING" or item.get("drainId") != drain_id:
            logger.warning(f"Invalid state for task {task_arn}: item={item}")
            _put_metric("ScalerInvalidState", 1, dimensions=[{"Name": "TaskArn", "Value": task_arn}])
            return _json({"message": "invalid state"}, 409)

        # Read cluster/service from item
        cluster_arn = item.get("clusterArn") or item.get("serviceClusterArn") or item.get("serviceArn", "").rsplit("/", 1)[0]
        service_arn = item.get("serviceArn")
        if not cluster_arn or not service_arn:
            logger.error(f"Missing cluster/service ARN for task {task_arn}")
            return _json({"message": "missing cluster/service ARN"}, 500)

        logger.info(f"Scaling out task {task_arn} from service {service_arn}")

        # Disable protection first
        try:
            ecs.update_task_protection(cluster=cluster_arn, tasks=[task_arn], protectionEnabled=False)
            logger.info(f"Disabled task protection for {task_arn}")
        except ClientError as e:
            logger.warning(f"Failed to disable task protection for {task_arn}: {e}")
            # Continue; protection off may already be false

        # Check min capacity before decrementing
        svc = ecs.describe_services(cluster=cluster_arn, services=[service_arn]).get("services", [])[0]
        desired = svc.get("desiredCount", 1)
        parts = service_arn.split(":service/")[-1]
        cluster_name = parts.split("/")[0]
        service_name = parts.split("/")[1]
        resource_id = f"service/{cluster_name}/{service_name}"
        sts = appscaling.describe_scalable_targets(ServiceNamespace="ecs", ResourceIds=[resource_id]).get("ScalableTargets", [])
        min_capacity = sts[0]["MinCapacity"] if sts else 0
        
        if desired <= min_capacity:
            logger.info(f"Service {service_arn} at min capacity: {desired} <= {min_capacity}")
            _put_metric("ScalerSkipped", 1, dimensions=[{"Name": "Reason", "Value": "at_min_capacity"}])
            return _json({"status": "skipped", "reason": "at_min_capacity", "desired": desired, "min": min_capacity})
        
        # Decrement desired count
        if desired > 0:
            try:
                ecs.update_service(cluster=cluster_arn, service=service_arn, desiredCount=desired - 1)
                logger.info(f"Decremented desired count for {service_arn} from {desired} to {desired - 1}")
            except ClientError as e:
                logger.error(f"Failed to update service {service_arn}: {e}")
                _put_metric("ScalerErrors", 1, dimensions=[{"Name": "Reason", "Value": "update_service_failed"}])
                return _json({"message": "failed to update service"}, 500)

        # Mark as SCALED_OUT
        table.update_item(
            Key={"taskArn": task_arn},
            UpdateExpression="SET #s=:so, completedAt=:ca",
            ExpressionAttributeNames={"#s": "state"},
            ExpressionAttributeValues={":so": "SCALED_OUT", ":ca": int(time.time())},
        )

        # Record metrics
        _put_metric("ScaleOutCompleted", 1, dimensions=[
            {"Name": "ServiceArn", "Value": service_arn},
            {"Name": "TaskArn", "Value": task_arn}
        ])
        _put_metric("DrainingCount", -1, dimensions=[
            {"Name": "ServiceArn", "Value": service_arn}
        ])

        logger.info(f"Successfully scaled out task {task_arn}")
        return _json({"status": "scaled", "desired": max(desired - 1, 0)})

    except Exception as e:
        logger.error(f"Unexpected error in scaler: {e}", exc_info=True)
        _put_metric("ScalerErrors", 1, dimensions=[{"Name": "Reason", "Value": "unexpected_error"}])
        return _json({"message": "internal server error"}, 500)


