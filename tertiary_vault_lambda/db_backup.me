import os
import boto3
import subprocess

def lambda_handler(event, context):
    # 配置参数
    bucket = os.environ['S3_BUCKET']       # S3 桶名，从环境变量获取
    key = "backup.sql"                     # 上传后的对象名
    pg_host = os.environ['RDS_ENDPOINT']     # RDS 实例地址
    pg_db = os.environ['RDS_DB_NAME']        # 数据库名称
    pg_user = os.environ['DB_USERNAME']      # 数据库用户名（使用 IAM 类型用户）
    # 这里假设 pg_dump 的认证（例如使用 IAM 认证生成的临时令牌）由程序内部处理
    # 如有需要，可通过环境变量传入其他认证信息

    # 初始化 S3 客户端
    s3_client = boto3.client('s3')

    # 启动 S3 Multipart Upload
    multipart = s3_client.create_multipart_upload(Bucket=bucket, Key=key)
    upload_id = multipart['UploadId']
    parts = []
    part_number = 1

    # 定义分块大小（例如 8MB）
    chunk_size = 8 * 1024 * 1024

    # 构造 pg_dump 命令，使用 -f - 将输出发送到 stdout
    pg_dump_cmd = [
        "pg_dump",
        "-h", pg_host,
        "-U", pg_user,
        "-p", "5432",      # 根据实际情况调整端口
        pg_db,
        "-f", "-"         # 将输出发送到标准输出
    ]

    # 设置必要的环境变量以供 pg_dump 使用（例如 PGPASSWORD 可以留空，若使用 IAM token 可直接替换）
    pg_env = os.environ.copy()

    try:
        # 启动 pg_dump 进程
        process = subprocess.Popen(pg_dump_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=pg_env)
        while True:
            # 从 stdout 中读取固定大小的数据块
            data = process.stdout.read(chunk_size)
            if not data:
                break  # 数据读取完毕

            # 上传当前分块到 S3
            response = s3_client.upload_part(
                Bucket=bucket,
                Key=key,
                PartNumber=part_number,
                UploadId=upload_id,
                Body=data
            )
            parts.append({
                'ETag': response['ETag'],
                'PartNumber': part_number
            })
            part_number += 1

        # 确保 pg_dump 进程结束，并检查是否出错
        stdout, stderr = process.communicate()
        if process.returncode != 0:
            raise Exception(f"pg_dump failed: {stderr.decode('utf-8')}")

        # 完成 Multipart Upload，将所有分块合并
        s3_client.complete_multipart_upload(
            Bucket=bucket,
            Key=key,
            UploadId=upload_id,
            MultipartUpload={'Parts': parts}
        )
    except Exception as e:
        # 若出错则中止上传
        s3_client.abort_multipart_upload(Bucket=bucket, Key=key, UploadId=upload_id)
        raise e

    return {
        'statusCode': 200,
        'body': f'Backup uploaded successfully with {len(parts)} parts.'
    }
