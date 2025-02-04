# Lambda Backup 模块

此模块用于创建一个基于 ECR 镜像运行的 Lambda 函数，并部署于指定 VPC 内，同时配置：
  
- IAM Role（通过模板文件定义日志、S3、KMS 及 RDS IAM 认证所需的权限）；
- Lambda 函数配置（支持自定义架构，如设置 "arm64" 以使用 Graviton；支持预留并发和 X-Ray 追踪）；
- EventBridge 定时规则，用于定时触发 Lambda 执行 RDS 数据备份任务；
- 可选的 CloudWatch 报警资源，用于监控 Lambda 错误数和平均执行时长。

调用模块时，VPC、RDS 和 S3 的配置通过对象类型传入，接口清晰且易于扩展。注意：RDS 使用 IAM 认证连接时，请确保 RDS 已启用相应配置，并正确传入 `db_resource_arn`。

使用示例请参阅根目录中的示例配置。
