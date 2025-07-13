variable "ecs_cluster_arn" {
  description = "ECS集群ARN"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS服务名"
  type        = string
}

variable "lambda_function_arn" {
  description = "目标Lambda函数ARN"
  type        = string
}

variable "eventbridge_rule_name" {
  description = "EventBridge规则名称"
  type        = string
  default     = "ecs-service-autoscaling-to-lambda"
}

resource "aws_cloudwatch_event_rule" "ecs_service_autoscaling" {
  name        = var.eventbridge_rule_name
  description = "Trigger Lambda on ECS Service Auto Scaling events"
  event_pattern = jsonencode({
    "source": ["aws.application-autoscaling"],
    "detail-type": ["ECS Service Action"],
    "detail": {
      "serviceNamespace": ["ecs"],
      "resourceId": [
        "service/${replace(var.ecs_cluster_arn, ":cluster/", ":")}/${var.ecs_service_name}"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.ecs_service_autoscaling.name
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_service_autoscaling.arn
} 