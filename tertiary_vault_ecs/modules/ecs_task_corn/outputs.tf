output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = aws_ecs_task_definition.ecs_task.arn
}

output "ecs_task_execution_role_arn" {
  description = "IAM Role ARN for ECS Task Execution"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "IAM Role ARN for ECS Task"
  value       = aws_iam_role.ecs_task_role.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group for ECS Task"
  value       = aws_cloudwatch_log_group.ecs_log_group.name
}

output "eventbridge_rule_name" {
  description = "EventBridge Rule Name"
  value       = aws_cloudwatch_event_rule.ecs_task_schedule.name
}

output "eventbridge_rule_arn" {
  description = "EventBridge Rule ARN"
  value       = aws_cloudwatch_event_rule.ecs_task_schedule.arn
}
