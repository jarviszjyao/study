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

variable "eventbridge_rule_name_task" {
  description = "EventBridge规则名称（Task State Change）"
  type        = string
  default     = "ecs-task-state-change-to-lambda"
}

variable "eventbridge_rule_name_scale" {
  description = "EventBridge规则名称（Service Action）"
  type        = string
  default     = "ecs-service-action-to-lambda"
}

# ECS Task State Change
resource "aws_cloudwatch_event_rule" "ecs_task_state_change" {
  name        = var.eventbridge_rule_name_task
  description = "Trigger Lambda on ECS Task State Change"
  event_pattern = jsonencode({
    "source": ["aws.ecs"],
    "detail-type": ["ECS Task State Change"],
    "detail": {
      "clusterArn": [var.ecs_cluster_arn],
      "group": ["service:${var.ecs_service_name}"],
      "lastStatus": ["RUNNING", "STOPPED"]
    }
  })
}

# ECS Service Action (Auto Scaling)
resource "aws_cloudwatch_event_rule" "ecs_service_action" {
  name        = var.eventbridge_rule_name_scale
  description = "Trigger Lambda on ECS Service Action"
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

resource "aws_cloudwatch_event_target" "lambda_task" {
  rule      = aws_cloudwatch_event_rule.ecs_task_state_change.name
  arn       = var.lambda_function_arn
}

resource "aws_cloudwatch_event_target" "lambda_scale" {
  rule      = aws_cloudwatch_event_rule.ecs_service_action.name
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge_task" {
  statement_id  = "AllowExecutionFromEventBridgeTask"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_state_change.arn
}

resource "aws_lambda_permission" "allow_eventbridge_scale" {
  statement_id  = "AllowExecutionFromEventBridgeScale"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_service_action.arn
}

# Lambda需要有ssm:SendCommand权限
resource "aws_iam_policy" "lambda_ssm_send_command" {
  name        = "lambda-ssm-send-command"
  description = "Allow Lambda to send SSM commands"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:SendCommand",
          "ssm:ListDocuments",
          "ssm:ListCommandInvocations"
        ],
        Resource = "*"
      }
    ]
  })
} 