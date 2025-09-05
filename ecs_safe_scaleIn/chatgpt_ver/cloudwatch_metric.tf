resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
    alarm_name          = "ecs-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/ECS"
    period              = 60
    statistic           = "Average"
    threshold           = 70
  
    dimensions = {
      ClusterName = var.ecs_cluster_name
      ServiceName = var.ecs_service_name
    }
  
    alarm_actions = [aws_appautoscaling_policy.scale_out.arn]
  }
  
  resource "aws_cloudwatch_metric_alarm" "ecs_cpu_low" {
    alarm_name          = "ecs-cpu-low"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/ECS"
    period              = 60
    statistic           = "Average"
    threshold           = 30
  
    dimensions = {
      ClusterName = var.ecs_cluster_name
      ServiceName = var.ecs_service_name
    }
  
    alarm_actions = [aws_appautoscaling_policy.scale_in.arn]
  }
  