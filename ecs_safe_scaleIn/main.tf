resource "aws_dynamodb_table" "drain_states" {
  name         = "${local.name_prefix}-drain-states"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "taskArn"

  attribute {
    name = "taskArn"
    type = "S"
  }

  attribute {
    name = "serviceArn"
    type = "S"
  }

  attribute {
    name = "state"
    type = "S"
  }

  global_secondary_index {
    name            = "service-state-index"
    hash_key        = "serviceArn"
    range_key       = "state"
    projection_type = "ALL"
  }
}

data "aws_iam_policy_document" "scale_manager_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scale_manager_role" {
  name               = "${local.name_prefix}-scale-manager-role"
  assume_role_policy = data.aws_iam_policy_document.scale_manager_assume.json
}

data "aws_iam_policy_document" "scale_manager_policy" {
  statement {
    actions = [
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:DescribeServices",
      "ecs:UpdateTaskProtection",
      "ecs:ListServices"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [var.kamailio_lambda_arn]
  }

  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:GetItem", "dynamodb:Query"]
    resources = [aws_dynamodb_table.drain_states.arn, "${aws_dynamodb_table.drain_states.arn}/index/*"]
  }

  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

  statement {
    actions   = ["application-autoscaling:DescribeScalableTargets"]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "scale_manager_inline" {
  name   = "${local.name_prefix}-scale-manager-policy"
  role   = aws_iam_role.scale_manager_role.id
  policy = data.aws_iam_policy_document.scale_manager_policy.json
}

data "aws_iam_policy_document" "scaler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scaler_role" {
  name               = "${local.name_prefix}-scaler-role"
  assume_role_policy = data.aws_iam_policy_document.scaler_assume.json
}

data "aws_iam_policy_document" "scaler_policy" {
  statement {
    actions = [
      "ecs:UpdateTaskProtection",
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
    resources = [aws_dynamodb_table.drain_states.arn]
  }

  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["application-autoscaling:DescribeScalableTargets"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "scaler_inline" {
  name   = "${local.name_prefix}-scaler-policy"
  role   = aws_iam_role.scaler_role.id
  policy = data.aws_iam_policy_document.scaler_policy.json
}

data "archive_file" "scale_manager_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/scale_manager"
  output_path = "${path.module}/dist/scale_manager.zip"
}

data "archive_file" "scaler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/scaler"
  output_path = "${path.module}/dist/scaler.zip"
}

resource "aws_lambda_function" "scale_manager" {
  function_name = "${local.name_prefix}-scale-manager"
  role          = aws_iam_role.scale_manager_role.arn
  handler       = "app.handler"
  runtime       = "python3.12"
  filename      = data.archive_file.scale_manager_zip.output_path
  timeout       = 60
  environment {
    variables = {
      TABLE_NAME               = aws_dynamodb_table.drain_states.name
      KAMAILIO_LAMBDA_ARN      = var.kamailio_lambda_arn
      DRAIN_TIMEOUT_SECONDS    = tostring(var.drain_timeout_seconds)
      DRAIN_CONCURRENCY_LIMIT  = tostring(var.drain_concurrency_limit)
      ASTERISK_HTTP_PORT       = tostring(var.asterisk_http_port)
      ASTERISK_HTTP_SCHEME     = var.asterisk_http_scheme
      SCALER_FUNCTION_URL      = aws_lambda_function_url.scaler.function_url
      SHARED_TOKEN             = var.shared_token
      COOLDOWN_SECONDS         = "900"
      MAX_DRAINS_PER_HOUR      = "2"
    }
  }
}

resource "aws_lambda_function" "scaler" {
  function_name = "${local.name_prefix}-scaler"
  role          = aws_iam_role.scaler_role.arn
  handler       = "app.handler"
  runtime       = "python3.12"
  filename      = data.archive_file.scaler_zip.output_path
  timeout       = 60
  environment {
    variables = {
      TABLE_NAME            = aws_dynamodb_table.drain_states.name
      SHARED_TOKEN          = var.shared_token
    }
  }
}

resource "aws_lambda_function_url" "scaler" {
  function_name      = aws_lambda_function.scaler.arn
  authorization_type = "NONE"
  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
  }
}

resource "aws_lambda_permission" "allow_eventbridge_scale_manager" {
  statement_id  = "AllowEventBridgeInvokeScaleManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_manager.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.protected_scale_in_attempt.arn
}

resource "aws_cloudwatch_event_rule" "protected_scale_in_attempt" {
  name        = "${local.name_prefix}-protected-scale-in-attempt"
  description = "Capture ECS protected scale-in attempts"
  
  event_pattern = jsonencode({
    source = ["aws.ecs"]
    "detail-type" = ["ECS Task State Change"]
    detail = {
      containers = {
        reason = ["protectedScaleInAttempt"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "protected_scale_in_target" {
  rule      = aws_cloudwatch_event_rule.protected_scale_in_attempt.name
  target_id = "scale-manager"
  arn       = aws_lambda_function.scale_manager.arn
}


