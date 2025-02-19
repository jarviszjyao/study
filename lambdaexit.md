import os
import boto3
import subprocess
import sys

def generate_auth_token():
    """
    通过 boto3 生成 RDS IAM 认证令牌，用于连接 RDS PostgreSQL。
    """
    rds_client = boto3.client('rds')
    token = rds_client.generate_db_auth_token(
        DBHostname=os.environ['RDS_ENDPOINT'],
        Port=int(os.environ['RDS_DB_PORT']),
        DBUsername=os.environ['DB_USERNAME']
    )
    return token

def stream_pg_dump_to_s3():
    # 生成认证令牌，并设置 PGPASSWORD 环境变量
    auth_token = generate_auth_token()
    env = os.environ.copy()
    env['PGPASSWORD'] = auth_token

    # 构造 pg_dump 命令，-f "-" 表示输出到标准输出
    pg_dump_cmd = [
        "pg_dump",
        "--host=" + os.environ['RDS_ENDPOINT'],
        "--port=" + os.environ['RDS_DB_PORT'],
        "--username=" + os.environ['DB_USERNAME'],
        "--dbname=" + os.environ['RDS_DB_NAME'],
        "--sslmode=require",
        "-f", "-"
    ]

    # 初始化 S3 客户端，并启动 Multipart Upload
    s3_client = boto3.client('s3')
    bucket = os.environ['S3_BUCKET']
    key = os.environ.get('S3_KEY', 'backup.sql')
    multipart_upload = s3_client.create_multipart_upload(Bucket=bucket, Key=key)
    upload_id = multipart_upload['UploadId']
    parts = []
    part_number = 1
    # 定义每个分块大小为 8MB（除最后一个分块外，S3 要求最小 5MB）
    chunk_size = 8 * 1024 * 1024

    # 启动 pg_dump 进程，将数据库导出到标准输出
    process = subprocess.Popen(pg_dump_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    
    try:
        while True:
            # 从 pg_dump 输出流中按固定大小读取数据块
            data = process.stdout.read(chunk_size)
            if not data:
                break

            # 上传当前分块到 S3
            response = s3_client.upload_part(
                Bucket=bucket,
                Key=key,
                PartNumber=part_number,
                UploadId=upload_id,
                Body=data
            )
            parts.append({'ETag': response['ETag'], 'PartNumber': part_number})
            part_number += 1

        # 等待 pg_dump 结束，并捕获错误信息
        stdout, stderr = process.communicate()
        if process.returncode != 0:
            raise Exception(f"pg_dump 失败: {stderr.decode('utf-8')}")

        # 完成 Multipart Upload
        s3_client.complete_multipart_upload(
            Bucket=bucket,
            Key=key,
            UploadId=upload_id,
            MultipartUpload={'Parts': parts}
        )
        print(f"备份成功上传到 S3，共分 {len(parts)} 个分块。")
    except Exception as e:
        # 发生异常时中止 Multipart Upload，防止产生不完整对象
        s3_client.abort_multipart_upload(Bucket=bucket, Key=key, UploadId=upload_id)
        print("上传过程中发生错误，已中止 Multipart Upload。")
        raise e

def lambda_handler(event, context):
    """
    Lambda 入口函数，完成 pg_dump 导出并上传到 S3 后，返回成功结果，确保不会被重试。
    """
    stream_pg_dump_to_s3()
    # 返回成功状态，通知 Lambda 任务已正常结束
    return {
        'statusCode': 200,
        'body': 'Backup process completed successfully.'
    }

if __name__ == "__main__":
    # 本地测试入口
    result = lambda_handler({}, None)
    print(result)
    sys.exit(0)
