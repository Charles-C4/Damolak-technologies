data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# CloudWatch Logs Policy for ECS Task Execution Role
resource "aws_iam_role_policy" "ecs_task_execution_logs_policy" {
  name = "ecs-task-execution-logs-policy"
  role = data.aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# CI/CD Pipeline User
resource "aws_iam_user" "cicd_user" {
  name = "devops-cicd-user"

  tags = {
    Name        = "devops-cicd-user"
    Purpose     = "CI/CD Pipeline"
    Environment = "production"
  }
}

# Access key for CI/CD user
resource "aws_iam_access_key" "cicd_user_key" {
  user = aws_iam_user.cicd_user.name
}

# ECR Policy for CI/CD user
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "devops-ecr-push-policy"
  description = "Policy for pushing Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRGetAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushImage"
        Effect = "Allow"
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages"
        ]
        Resource = "arn:aws:ecr:*:*:repository/*"
      }
    ]
  })
}

# ECS Policy for CI/CD user
resource "aws_iam_policy" "ecs_update_policy" {
  name        = "devops-ecs-update-policy"
  description = "Policy for updating ECS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSUpdateService"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeCluster",
          "ecs:ListServices"
        ]
        Resource = [
          "arn:aws:ecs:*:*:cluster/*",
          "arn:aws:ecs:*:*:service/*/*",
          "arn:aws:ecs:*:*:task-definition/*"
        ]
      }
    ]
  })
}

# Attach policies to CI/CD user
resource "aws_iam_user_policy_attachment" "cicd_ecr_policy_attachment" {
  user       = aws_iam_user.cicd_user.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}

resource "aws_iam_user_policy_attachment" "cicd_ecs_policy_attachment" {
  user       = aws_iam_user.cicd_user.name
  policy_arn = aws_iam_policy.ecs_update_policy.arn
}