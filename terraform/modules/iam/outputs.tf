output "execution_role_arn" {
  value = data.aws_iam_role.ecs_task_execution_role.arn
}

output "cicd_user_name" {
  description = "CI/CD user name"
  value       = aws_iam_user.cicd_user.name
}

output "cicd_access_key_id" {
  description = "CI/CD user access key ID"
  value       = aws_iam_access_key.cicd_user_key.id
  sensitive   = true
}

output "cicd_access_key_secret" {
  description = "CI/CD user secret access key"
  value       = aws_iam_access_key.cicd_user_key.secret
  sensitive   = true
}