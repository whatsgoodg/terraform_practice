provider "aws"{
    region = "ap-northeast-2" 
}

# auto scaling을 사용하며 삭제함.
# resource "aws_instance" "example" { 
#     ami = "ami-0f3a440bbcff3d043"
#     instance_type = "t3.micro" 
#     subnet_id = "subnet-045f18b2ad7211482"
#     vpc_security_group_ids = [aws_security_group.instance.id]

#     # 사용자 스크립트에서도 변수를 사용할 수 있다.
#     # 얘를 문자로 변경하면 멱등성이 파괴되더라..  
#     # 변수를 사용하면 무조건 멱등성이 파괴된다.
#     user_data = <<-EOF
#     #!/bin/bash
#     echo "Hello, World" > index.html 
#     nohup busybox httpd -f -p 8080 &  
#     EOF
#     # 얘가 대체하는 옵션인거 같은데 그냥 ? 
#     user_data_replace_on_change  =  true 
#     tags = {
#         Name = "terraform-example"
#     }
# }

# Application Load Balancer 생성
resource "aws_lb" "example"{
    name = "terraform-asg-example"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

# ALB listener 구성, 트래픽 캡쳐 설정
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    # port 80으로 들어오는 http를 받음
    port = 80
    protocol = "HTTP"
    # page가 존재하지 않거나, 웹 서버가 healthy하지 않을 때
    default_action{
        type = "fixed-response"
        fixed_response{
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

# ALB sg
resource "aws_security_group" "alb"{
    name = "terraform-example-alb"
    vpc_id = data.aws_vpc.default.id
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # outbound packet
    # 모든 트래픽이 나가게 설정한 것임.
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# ALB Target group
resource "aws_lb_target_group" "asg"{
    name = "terraform-asg-example"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    health_check{
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    vpc_id = "vpc-033ceae946fa9afd3"
    ingress{
        from_port = var.server_port
        to_port = var.server_port # var.[Var Name] 형식으로 변수를 사용할 수 있음.
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

variable "server_port"{ # default 변수가 명시되어 있지 않으면 CLI에서 물어볼 것임, 또는 옵션으로 처리할 수 있음.
    description = "server port http request"
    default = 8080
    type = number
}

# output "public_ip" {
#     description = "Web Server Public IP"
#     value = aws_instance.example.public_ip
# }

# auto scailing group 구성
# 시작 템플릿과 다른, 시작 구성을 사용함.
# 요즘엔 시작 구성을 권장함. -> launch configuration
resource "aws_launch_configuration" "example" {
    image_id = "ami-0f3a440bbcff3d043"
    instance_type = "t3.micro" 
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html 
    nohup busybox httpd -f -p 8080 &  
    EOF
    # 얘를 설정하지 않으면, terraform이 시작 구성을 삭제하기 이전에, instance를 먼저 삭제하려 수행한다.
    # 그럼, load balancer는 이를 또 min_size를 유지하기 위해 생성을 할 것이다.
    # 이러한 이유로 먼저 시작 구성을 삭제할 수 없다.
        # 그런데 테라폼이 이를 막는지, 삭제는 되는데 계속 생성/삭제를 반복하는진 모르겠다
    # 이를 lifecycle로 해결할 수 있다.
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        path_pattern {
            values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

output "alb_dns_name" {
    value = aws_lb.example.dns_name
    description = "The domain name of the load balancer"
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnets.default.ids
    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"
    min_size = 2
    max_size = 10

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
}

# 프로바이더가 제공하는 데이터 사용
# 데이터 소스
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