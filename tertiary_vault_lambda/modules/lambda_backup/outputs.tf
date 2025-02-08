output "lambda_function_arn" {
  description = "Lambda 函数 ARN"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Lambda 函数名称"
  value       = aws_lambda_function.this.function_name
}

output "iam_role_arn" {
  description = "Lambda 执行角色 ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "event_rule_arn" {
  description = "EventBridge 定时规则 ARN"
  value       = aws_cloudwatch_event_rule.lambda_schedule.arn
}
