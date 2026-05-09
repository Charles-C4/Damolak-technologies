resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/devops-task"
  retention_in_days = 7

  tags = {
    Name        = "devops-ecs-logs"
    Environment = "production"
  }
}

resource "aws_cloudwatch_log_stream" "ecs_log_stream" {
  name           = "devops-container-logs"
  log_group_name = aws_cloudwatch_log_group.ecs_logs.name
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "devops_dashboard" {
  dashboard_name = "devops-deployment-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "ServiceCount", { stat = "Average" }],
            [".", "RunningCount", { stat = "Sum" }],
            [".", "DesiredCount", { stat = "Sum" }],
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }],
            [".", "HealthyHostCount", { stat = "Average" }],
            [".", "UnHealthyHostCount", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "ECS and ALB Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | stats count() by @message | sort count() desc"
          region  = "us-east-1"
          title   = "ECS Container Logs"
        }
      }
    ]
  })
}

# CloudWatch Alarm - Unhealthy Targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "devops-unhealthy-targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when ALB has unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = "app/devops-alb/*"
  }

  tags = {
    Name = "devops-unhealthy-targets-alarm"
  }
}

# CloudWatch Alarm - High Response Time
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "devops-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when response time exceeds 1 second"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = "app/devops-alb/*"
  }

  tags = {
    Name = "devops-high-response-time-alarm"
  }
}

# CloudWatch Alarm - ECS Task CPU
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "devops-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when ECS task CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "devops-cluster"
    ServiceName = "devops-service"
  }

  tags = {
    Name = "devops-ecs-cpu-high-alarm"
  }
}

# CloudWatch Alarm - ECS Task Memory
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "devops-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when ECS task memory exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "devops-cluster"
    ServiceName = "devops-service"
  }

  tags = {
    Name = "devops-ecs-memory-high-alarm"
  }
}

# SNS Topic for Alarms (optional - for notifications)
resource "aws_sns_topic" "devops_alerts" {
  name = "devops-alerts"

  tags = {
    Name = "devops-alerts-topic"
  }
}

resource "aws_sns_topic_subscription" "devops_alerts_email" {
  topic_arn = aws_sns_topic.devops_alerts.arn
  protocol  = "email"
  endpoint  = "charles@damolak.com"
}

# Connect Alarms to SNS Topic
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets_with_sns" {
  alarm_name          = "devops-unhealthy-targets-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when ALB has unhealthy targets"
  alarm_actions       = [aws_sns_topic.devops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = "app/devops-alb/*"
  }

  tags = {
    Name = "devops-unhealthy-targets-alert"
  }
}
