resource "aws_ecs_cluster" "this" {
  name = "devops-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "devops-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn      = var.execution_role

  container_definitions = jsonencode([
    {
      name  = "devops-container"
      image = "${var.ecr_url}:latest"
      portMappings = [{
        containerPort = 80
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/devops-task"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "devops-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnets
    assign_public_ip = true
    security_groups = [var.security_group]
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "devops-container"
    container_port   = 80
  }

  depends_on = [aws_ecs_task_definition.this]
}