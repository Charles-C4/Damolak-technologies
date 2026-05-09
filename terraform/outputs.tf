output "alb_dns_name" {
  description = "Public DNS of the Load Balancer"
  value       = module.alb.alb_dns
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = module.ecs.cluster_name
}