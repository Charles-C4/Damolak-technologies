variable "ecr_url" {}
variable "execution_role" {}
variable "subnets" {
  type = list(string)
}

variable "security_group" {}

variable "target_group_arn" {}