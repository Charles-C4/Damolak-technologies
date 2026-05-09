output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.ecs_logs.arn
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.devops_dashboard.dashboard_name}"
}

output "sns_topic_arn" {
  description = "SNS Topic for alarm notifications"
  value       = aws_sns_topic.devops_alerts.arn
}
