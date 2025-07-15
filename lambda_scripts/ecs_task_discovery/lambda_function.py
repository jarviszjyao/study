import os
import json
import logging
import boto3
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
EFS_MOUNT_PATH = os.environ.get("EFS_MOUNT_PATH", "/mnt/efs")
EFS_IPLIST_FILE = os.environ.get("EFS_IPLIST_FILE", "iplist.txt")
HEALTH_CHECK_PORT = int(os.environ.get("HEALTH_CHECK_PORT", 80))
RETRY_COUNT = int(os.environ.get("RETRY_COUNT", 3))
RETRY_INTERVAL = int(os.environ.get("RETRY_INTERVAL", 5))  # 秒
HEALTH_CHECK_TIMEOUT = float(os.environ.get("HEALTH_CHECK_TIMEOUT", 2.0))  # 秒

# Lambda最大执行时间保护（秒）
LAMBDA_TIMEOUT_BUFFER = int(os.environ.get("LAMBDA_TIMEOUT_BUFFER", 5))  # 预留5秒
SSM_DOCUMENT_NAME = os.environ.get("SSM_DOCUMENT_NAME")
SSM_INSTANCE_IDS = os.environ.get("SSM_INSTANCE_IDS", "").split(",") if os.environ.get("SSM_INSTANCE_IDS") else []

# 初始化boto3客户端
ecs_client = boto3.client("ecs")
ec2_client = boto3.client("ec2")
ssm_client = boto3.client("ssm")

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

def read_efs_iplist(filepath):
    ip_set = set()
    try:
        with open(filepath, "r") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                # 假设格式为: 1 sip:128.164.92.23:5060;transport=tcp ...
                parts = line.split()
                if len(parts) >= 2 and parts[1].startswith("sip:"):
                    ip_port = parts[1][4:].split(":")[0]  # 取IP部分
                    ip_set.add(ip_port)
    except FileNotFoundError:
        logger.info(f"EFS文件{filepath}不存在，将新建。")
    except Exception as e:
        logger.error(f"读取EFS IP列表文件失败: {e}")
    return ip_set

def append_efs_iplist(filepath, new_entries):
    try:
        with open(filepath, "a") as f:
            for entry in new_entries:
                # 格式: 1 sip:IP:5060;transport=tcp 8 12 rweight=100;weight=99,cc=1
                line = f"1 sip:{entry['ip']}:5060;transport=tcp 8 12 rweight=100;weight=99,cc=1\n"
                f.write(line)
        logger.info(f"已追加{len(new_entries)}条新IP到EFS文件: {filepath}")
    except Exception as e:
        logger.error(f"写入EFS IP列表文件失败: {e}")
        raise

def remove_ip_from_efs(filepath, ip_to_remove):
    try:
        lines = []
        removed = False
        with open(filepath, "r") as f:
            for line in f:
                if ip_to_remove not in line:
                    lines.append(line)
                else:
                    removed = True
        if removed:
            with open(filepath, "w") as f:
                f.writelines(lines)
            logger.info(f"已从EFS文件移除IP: {ip_to_remove}")
    except FileNotFoundError:
        logger.info(f"EFS文件{filepath}不存在，无需移除IP。")
    except Exception as e:
        logger.error(f"移除EFS IP失败: {e}")
        raise

def trigger_ssm_document():
    if SSM_DOCUMENT_NAME and SSM_INSTANCE_IDS:
        try:
            response = ssm_client.send_command(
                InstanceIds=SSM_INSTANCE_IDS,
                DocumentName=SSM_DOCUMENT_NAME,
            )
            logger.info(f"已触发SSM Document: {SSM_DOCUMENT_NAME}, response: {response}")
        except Exception as e:
            logger.error(f"触发SSM Document失败: {e}")

# 只处理单个task的IP增删

def handle_single_task(event):
    efs_file = os.path.join(EFS_MOUNT_PATH, EFS_IPLIST_FILE)
    detail = event.get("detail", {})
    task_arn = detail.get("taskArn")
    last_status = detail.get("lastStatus")
    containers = detail.get("containers", [])
    ip = None
    for c in containers:
        for ni in c.get("networkInterfaces", []):
            if "privateIpv4Address" in ni:
                ip = ni["privateIpv4Address"]
                break
    logger.info(f"单task事件: taskArn={task_arn}, status={last_status}, ip={ip}")
    if last_status == "RUNNING" and ip:
        # 健康检查
        if is_healthy(ip, HEALTH_CHECK_PORT, HEALTH_CHECK_TIMEOUT):
            existing_ips = read_efs_iplist(efs_file)
            if ip not in existing_ips:
                append_efs_iplist(efs_file, [{"ip": ip, "task_name": task_arn, "update_time": datetime.utcnow().isoformat() + "Z", "status": last_status}])
            else:
                logger.info(f"IP {ip} 已存在EFS文件，无需追加。")
        else:
            logger.warning(f"IP {ip} 健康检查未通过，未写入EFS。")
    elif last_status == "STOPPED" and ip:
        remove_ip_from_efs(efs_file, ip)
    else:
        logger.info("事件未包含有效IP或状态，跳过处理。")

# 全量处理所有task

def handle_full_service(context):
    efs_file = os.path.join(EFS_MOUNT_PATH, EFS_IPLIST_FILE)
    start_time = time.time()
    lambda_timeout = (context.get_remaining_time_in_millis() / 1000) - LAMBDA_TIMEOUT_BUFFER if context else 900
    all_healthy_ips = set()
    while True:
        tasks = get_ecs_tasks(ECS_CLUSTER_NAME, ECS_SERVICE_NAME)
        healthy_ip_list = []
        unhealthy_ip_list = []
        for task in tasks:
            info = get_task_ip_and_status(task)
            if info["ip"] and is_healthy(info["ip"], HEALTH_CHECK_PORT, HEALTH_CHECK_TIMEOUT):
                healthy_ip_list.append(info)
            elif info["ip"]:
                unhealthy_ip_list.append(info)
        logger.info(f"本轮健康IP: {[i['ip'] for i in healthy_ip_list]}")
        logger.info(f"本轮未健康IP: {[i['ip'] for i in unhealthy_ip_list]}")
        existing_ips = read_efs_iplist(efs_file)
        new_entries = [info for info in healthy_ip_list if info["ip"] and info["ip"] not in existing_ips]
        if new_entries:
            append_efs_iplist(efs_file, new_entries)
            all_healthy_ips.update([info["ip"] for info in new_entries])
        elapsed = time.time() - start_time
        if not unhealthy_ip_list or elapsed > lambda_timeout:
            if unhealthy_ip_list:
                logger.warning(f"超时退出，仍有未健康IP: {[i['ip'] for i in unhealthy_ip_list]}")
            break
        logger.info(f"等待{RETRY_INTERVAL}秒后重试未健康IP...")
        time.sleep(RETRY_INTERVAL)
    return {"status": "success", "new_ip_count": len(all_healthy_ips)}

def lambda_handler(event, context):
    logger.info(f"事件: {json.dumps(event)}")
    try:
        if event.get("source") == "aws.ecs" and event.get("detail-type") == "ECS Task State Change":
            handle_single_task(event)
        elif event.get("source") == "aws.application-autoscaling" and event.get("detail-type") == "ECS Service Action":
            handle_full_service(context)
        else:
            logger.warning("未知事件类型，默认全量处理")
            handle_full_service(context)
        trigger_ssm_document()
        return {"status": "success"}
    except Exception as e:
        logger.error(f"Lambda执行异常: {e}")
        return {"status": "error", "message": str(e)} 