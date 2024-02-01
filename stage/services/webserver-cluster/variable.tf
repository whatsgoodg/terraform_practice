variable "server_port"{ # default 변수가 명시되어 있지 않으면 CLI에서 물어볼 것임, 또는 옵션으로 처리할 수 있음.
    description = "server port http request"
    default = 8080
    type = number
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

# Read Only로 가져옴
data "terraform_remote_state" "db" {
    backend = "s3"
    config = {
        bucket = "terraform-state-cloudwave-bruh"
        key = "stage/data-stores/mysql/terraform.tfstate"
        region = "ap-northeast-2"
    }
}