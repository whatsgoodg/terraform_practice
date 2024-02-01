variable "db_username" {
    description = "The username for the database"
    type        = string
    sensitive   = true # plan 또는 apply 시 기록하지 않음.
}

# 위 아래 변수에는 default 값이 존재하지 않고, apply, plan을 수행해도 state file에 기록이 남지 않음.
# CLI option 또는 환경변수로 유저이름과 비밀번호를 전달할 수 있음.

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

data "aws_vpc" "default" {
    id = "vpc-033ceae946fa9afd3"
    # default = true # 기본 vpc를 가져옴
}

data "aws_subnets" "default" {
    filter{
        name = "vpc-id" # vpc id를 가져와서, 해당 vpc의 서브넷 id를 가져옴 
        values = [data.aws_vpc.default.id]
    }
}