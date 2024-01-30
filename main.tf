provider "aws"{
    region = "ap-northeast-2" # 서울 region에 생성 
}

resource "aws_instance" "example" {
    ami = "ami-0f3a440bbcff3d043"
    instance_type = "t3.micro" # a, c 밖에 안돼서 ? 
    subnet_id = "subnet-045f18b2ad7211482"

    tags = {
        Name = "terraform-example"
    }
}
