# More filters than needed. The last one is just an extra check to make sure my experimetn doesn't get applied to a prod VPC.
data "aws_vpc" "main" {
  filter {
    name   = "isDefault"
    values = ["false"]
  }
  filter {
    name   = "tag-key"
    values = ["Name"]
  }
  filter {
    name   = "tag:Owner"
    values = ["CloudOps"]
  }
}

#Just for debugging the above data source
output "aws_vpc" {
  value = data.aws_vpc.main.id
}

#What AMI to use? Since we are going to be running docker, lets use AL2 ECS optimized AMI. AWS provides this as an SSM Parameter. 
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

#Just for debugging the above data source
output "ecs_ami" {
  value     = data.aws_ssm_parameter.ecs_ami.value
  sensitive = true
}

#Get all the Private Subnets in the VPC
data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:SUB-Type"
    values = ["Private"]
  }
}

#Just for debugging the above data source
output "aws_subnet_ids" {
  value = data.aws_subnet_ids.subnets.ids
}


variable "ghe_pat" {
  type      = string
  sensitive = true
}

variable "nr_key" {
  type      = string
  sensitive = true
}

variable "nr_account" {
  type      = string
  sensitive = true
}

variable "iam_role_name" {
  type      = string
  sensitive = true
}

variable "iam_ip_arn" {
  type      = string
  sensitive = true
}

variable "iam_cwa_role_name" {
  type      = string
  sensitive = true
}


data "aws_iam_role" "iam_cwa_role_name" {
  name = var.iam_cwa_role_name
}


variable "iam_ssm_role" {
  type      = string
  sensitive = true
}

data "aws_iam_role" "iam_ssm_role" {
  name = var.iam_ssm_role
}

variable "environment" {
  type      = string
  sensitive = true
}

variable "ghes_base_url" {
  type      = string
  sensitive = true
}


variable "ghes_runner_target" {
  type      = string
  sensitive = true
}

variable "ghes_runner_labels" {
  type      = string
  sensitive = true
  default = ""
}

variable "ghes_runner_group" {
  type      = string
  sensitive = true
  default = "Test Enterprise Runners"
}

variable "pool_size_min" {
  type      = number
  sensitive = false
  default = 4
}

variable "pool_size_max" {
  type      = number
  sensitive = false
  default = 4
}
