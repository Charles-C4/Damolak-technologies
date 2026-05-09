provider "aws" {
  region = "us-east-1"
}
terraform {
  backend "s3" {
    bucket         = "devops-terraform-state-489270049918"
    key            = "devops/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

}
module "ecr" {
  source = "./modules/ecr"
}

module "iam" {
  source = "./modules/iam"
}

module "monitoring" {
  source = "./modules/monitoring"
}

module "alb" {
  source = "./modules/alb"

  vpc_id = "vpc-077bcbfe511aef7aa"
  subnets = [
    "subnet-0d2412da8c131976a",
    "subnet-07b2443080fc6bc11"
  ]
}

module "ecs" {
  source = "./modules/ecs"

  ecr_url         = module.ecr.repository_url
  execution_role  = module.iam.execution_role_arn
  subnets         = var.subnets
  security_group  = "sg-05ebe968c934ac4c6"
  target_group_arn = module.alb.target_group_arn
}