import os
import json
import logging
import boto3
import redis
import socket
import time
from datetime import datetime
from botocore.exceptions import ClientError

# 设置日志
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# 环境变量
ECS_CLUSTER_NAME = os.environ["ECS_CLUSTER_NAME"]
ECS_SERVICE_NAME = os.environ["ECS_SERVICE_NAME"]
REDIS_HOST = os.environ["REDIS_HOST"]
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
REDIS_SECRET_ARN = os.environ["REDIS_SECRET_ARN"]
REDIS_KEY = os.environ.get("REDIS_KEY", "ecs:task:iplist")
HEALTH_CHECK_PORT = int(os.environ.get("HEALTH_CHECK_PORT", 80))
RETRY_COUNT = int(os.environ.get("RETRY_COUNT", 3))
RETRY_INTERVAL = int(os.environ.get("RETRY_INTERVAL", 5))  # 秒
HEALTH_CHECK_TIMEOUT = float(os.environ.get("HEALTH_CHECK_TIMEOUT", 2.0))  # 秒

# 初始化boto3客户端
ecs_client = boto3.client("ecs")
ec2_client = boto3.client("ec2")
secrets_client = boto3.client("secretsmanager")

def get_redis_password(secret_arn):
    try:
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        secret = response["SecretString"]
        secret_dict = json.loads(secret)
        for k in ["password", "redis_password", "auth"]:
            if k in secret_dict:
                return secret_dict[k]
        return secret
    except Exception as e:
        logger.error(f"获取Redis密码失败: {e}")
        raise

def get_ecs_tasks(cluster, service):
    try:
        paginator = ecs_client.get_paginator("list_tasks")
        task_arns = []
        for page in paginator.paginate(cluster=cluster, serviceName=service, desiredStatus="RUNNING"):
            task_arns.extend(page["taskArns"])
        logger.info(f"发现{len(task_arns)}个RUNNING任务")
        if not task_arns:
            return []
        tasks = ecs_client.describe_tasks(cluster=cluster, tasks=task_arns)["tasks"]
        return tasks
    except Exception as e:
        logger.error(f"获取ECS任务失败: {e}")
        raise

def get_task_ip_and_status(task):
    eni_id = None
    ip = None
    status = task.get("lastStatus", "UNKNOWN")
    task_name = task.get("taskDefinitionArn", "").split("/")[-1]
    try:
        attachments = task.get("attachments", [])
        for att in attachments:
            if att["type"] == "ElasticNetworkInterface":
                for detail in att["details"]:
                    if detail["name"] == "networkInterfaceId":
                        eni_id = detail["value"]
                        break
        if eni_id:
            eni = ec2_client.describe_network_interfaces(NetworkInterfaceIds=[eni_id])["NetworkInterfaces"][0]
            ip = eni.get("PrivateIpAddress")
    except Exception as e:
        logger.warning(f"获取Task {task_name} ENI/IP失败: {e}")
    return {
        "ip": ip,
        "task_name": task_name,
        "update_time": datetime.utcnow().isoformat() + "Z",
        "status": status
    }

def is_healthy(ip, port, timeout=2.0):
    try:
        with socket.create_connection((ip, port), timeout=timeout):
            logger.info(f"健康检查通过: {ip}:{port}")
            return True
    except Exception as e:
        logger.warning(f"健康检查失败: {ip}:{port}, 错误: {e}")
        return False

def lambda_handler(event, context):
    logger.info(f"事件触发: {json.dumps(event)}")
    try:
        redis_password = get_redis_password(REDIS_SECRET_ARN)
        healthy_ip_list = []
        for attempt in range(RETRY_COUNT):
            logger.info(f"第{attempt+1}次尝试拉取ECS任务和健康检查...")
            tasks = get_ecs_tasks(ECS_CLUSTER_NAME, ECS_SERVICE_NAME)
            ip_list = []
            for task in tasks:
                info = get_task_ip_and_status(task)
                if info["ip"] and is_healthy(info["ip"], HEALTH_CHECK_PORT, HEALTH_CHECK_TIMEOUT):
                    ip_list.append(info)
            logger.info(f"本次健康的IP列表: {ip_list}")
            if ip_list:
                healthy_ip_list = ip_list
                break
            if attempt < RETRY_COUNT - 1:
                logger.info(f"未发现健康IP，等待{RETRY_INTERVAL}秒后重试...")
                time.sleep(RETRY_INTERVAL)
        # 写入Redis
        r = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, password=redis_password, decode_responses=True)
        r.set(REDIS_KEY, json.dumps(healthy_ip_list))
        logger.info(f"已写入Redis key: {REDIS_KEY}, 共{len(healthy_ip_list)}个健康IP")
        return {"status": "success", "count": len(healthy_ip_list)}
    except Exception as e:
        logger.error(f"Lambda执行异常: {e}")
        return {"status": "error", "message": str(e)} 