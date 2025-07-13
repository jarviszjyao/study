# ECS Task Discovery Lambda

**Python版本要求：3.9及以上（推荐3.11，兼容AWS Lambda Python 3.11运行时）**

本Lambda函数用于发现指定ECS Service下所有Task的IP、名称、状态，并同步到Elasticache Redis。适用于ECS服务自动扩缩容时的服务发现。

## 功能
- 由ECS Service的Auto Scaling事件触发，也可定时触发（EventBridge）
- 获取所有ECS Task的IP、Task Name、更新时间、状态
- **健康检查**：仅同步健康（端口可连通）的IP
- **重试机制**：支持多次拉取+健康检查，确保捕获最新Task
- 写入Redis（key为环境变量，值为JSON数组，每项含ip、task_name、update_time、status）
- Redis密码从Secrets Manager获取
- 关键步骤和结果输出到CloudWatch日志
- 完善异常处理

## 环境变量
| 变量名              | 说明                       |
|---------------------|----------------------------|
| ECS_CLUSTER_NAME    | ECS集群名                  |
| ECS_SERVICE_NAME    | ECS服务名                  |
| REDIS_HOST          | Redis主机地址              |
| REDIS_PORT          | Redis端口（默认6379）      |
| REDIS_SECRET_ARN    | Redis密码的Secrets ARN     |
| REDIS_KEY           | Redis中存储IP列表的key     |
| HEALTH_CHECK_PORT   | 健康检查端口（默认80）     |
| RETRY_COUNT         | 拉取+健康检查重试次数（默认3）|
| RETRY_INTERVAL      | 重试间隔秒数（默认5）      |
| HEALTH_CHECK_TIMEOUT| 健康检查超时秒数（默认2.0）|

## Redis密码Secret格式
建议如下（支持常见key）：
```json
{
  "password": "your_redis_password"
}
```

## 依赖
- boto3
- redis

## 打包部署
1. 安装依赖：
   ```bash
   pip install -r requirements.txt -t .
   ```
2. 打包上传：
   ```bash
   zip -r lambda.zip .
   # 上传到Lambda控制台
   ```

## 触发方式
- 推荐通过ECS Service的Auto Scaling事件（EventBridge）触发
- 也可定时触发（如每分钟同步，做最终一致性补偿）

## 健康检查与重试机制
- 每次事件触发后，Lambda会多次拉取ECS任务并做健康检查（TCP端口连通性）
- 只同步健康的IP到Redis
- 支持重试次数、间隔、端口、超时等参数化配置
- 保障ECS扩缩容时IP同步的可靠性和最终一致性

## Redis数据结构
- Redis Key: 由`REDIS_KEY`指定（如`ecs:task:iplist`）
- Value: JSON数组，每项结构如下：
```json
[
  {
    "ip": "10.0.1.123",
    "task_name": "ecs-task-def:1",
    "update_time": "2024-07-13T12:34:56Z",
    "status": "RUNNING"
  },
  ...
]
```

## CloudWatch日志
- 关键步骤、健康检查、重试、异常、同步结果均输出到日志，便于排查和监控。

## 权限要求
- Lambda需有权限：
  - `ecs:ListTasks`, `ecs:DescribeTasks`
  - `ec2:DescribeNetworkInterfaces`
  - `secretsmanager:GetSecretValue`
  - 访问Redis安全组

## 生产建议
- 建议事件+定时双触发，保障最终一致性
- 监控Lambda执行失败、健康IP为0等异常，及时告警
- 结合安全组和VPC Endpoint Policy，保障网络和权限安全 