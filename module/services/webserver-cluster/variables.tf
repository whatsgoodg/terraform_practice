variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}
variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}
variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

############################################################################
variable "server_port" { # default 변수가 명시되어 있지 않으면 CLI에서 물어볼 것임, 또는 옵션으로 처리할 수 있음.
  description = "server port http request"
  default     = 8080
  type        = number
}

data "aws_vpc" "default" {
  id = "vpc-033ceae946fa9afd3"
  # default = true # 기본 vpc를 가져옴
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id" # vpc id를 가져와서, 해당 vpc의 서브넷 id를 가져옴 
    values = [data.aws_vpc.default.id]
  }
}

# Read Only로 가져옴
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "${var.db_remote_state_bucket}-bruh"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
