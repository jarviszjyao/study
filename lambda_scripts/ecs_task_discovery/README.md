# ECS Task Discovery Lambda

**Python版本要求：3.9及以上（推荐3.11，兼容AWS Lambda Python 3.11运行时）**

本Lambda函数用于发现指定ECS Service下所有Task的IP、名称、状态，并同步到EFS文件。适用于ECS服务自动扩缩容时的服务发现。

## 功能
- 支持两类事件：
  - **ECS Task State Change**：精准处理单个task的IP增删。
  - **ECS Service Action**（如scale out/in）：全量处理所有task，兜底一致性。
- 事件自动触发SSM Document（通过Session Manager在EC2上执行命令）。
- 健康检查：仅同步健康（端口可连通）的IP。
- 重试机制：支持多次拉取+健康检查，确保捕获最新Task。
- 写入EFS（key为环境变量，值为指定格式，每项含ip、task_name、update_time、status）。
- 关键步骤和结果输出到CloudWatch日志。
- 完善异常处理。

## 环境变量
| 变量名              | 说明                       |
|---------------------|----------------------------|
| ECS_CLUSTER_NAME    | ECS集群名                  |
| ECS_SERVICE_NAME    | ECS服务名                  |
| EFS_MOUNT_PATH      | EFS挂载点（如/mnt/efs）    |
| EFS_IPLIST_FILE     | EFS中存储IP列表的文件名    |
| HEALTH_CHECK_PORT   | 健康检查端口（默认80）     |
| RETRY_INTERVAL      | 重试间隔秒数（默认5）      |
| HEALTH_CHECK_TIMEOUT| 健康检查超时秒数（默认2.0）|
| LAMBDA_TIMEOUT_BUFFER| Lambda超时保护（默认5秒） |
| SSM_DOCUMENT_NAME   | 要触发的SSM Document名称   |
| SSM_INSTANCE_IDS    | 逗号分隔的EC2实例ID列表    |

## 事件与处理逻辑
- **ECS Task State Change**：只处理event中的task（精准高效）。
- **ECS Service Action**：全量处理所有task（兜底一致性）。
- 处理完毕后自动触发SSM Document，可用于自动刷新、通知等。

## EFS数据结构
- 文件格式示例：
  ```
  1 sip:128.164.92.23:5060;transport=tcp 8 12 rweight=100;weight=99,cc=1
  ```
- 每行一个IP，格式可自定义。

## 依赖
- 仅需boto3

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
- 通过Terraform自动创建两类EventBridge规则：
  - 捕获ECS Task State Change事件（精准task变动）。
  - 捕获ECS Service Action事件（扩缩容兜底）。
- 两者都触发同一个Lambda。

## 健康检查与重试机制
- 每次事件触发后，Lambda会多次拉取ECS任务并做健康检查（TCP端口连通性）。
- 只同步健康的IP到EFS。
- 支持重试次数、间隔、端口、超时等参数化配置。
- 保障ECS扩缩容时IP同步的可靠性和最终一致性。

## CloudWatch日志
- 关键步骤、健康检查、重试、异常、同步结果均输出到日志，便于排查和监控。

## 权限要求
- Lambda需有权限：
  - `ecs:ListTasks`, `ecs:DescribeTasks`
  - `ec2:DescribeNetworkInterfaces`
  - `ssm:SendCommand`, `ssm:ListDocuments`, `ssm:ListCommandInvocations`
  - 访问EFS挂载点

## 生产建议
- 推荐主用Task State Change事件，Service Action事件做兜底。
- SSM Document可用于自动刷新、通知、或其它自动化操作。
- 监控Lambda执行失败、健康IP为0等异常，及时告警。
- 结合安全组和VPC Endpoint Policy，保障网络和权限安全。 