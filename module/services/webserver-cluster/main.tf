# module은 provider는 필요 없다 module에서 우린 참조만 할 뿐

# Application Load Balancer 생성
resource "aws_lb" "example" {
  name               = "${var.cluster_name}-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# ALB listener 구성, 트래픽 캡쳐 설정
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  # port 80으로 들어오는 http를 받음
  port     = local.http_port
  protocol = "HTTP"
  # page가 존재하지 않거나, 웹 서버가 healthy하지 않을 때
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# ALB sg
resource "aws_security_group" "alb" {
  name   = "${var.cluster_name}-alb"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.http.port
  to_port           = local.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}
# ALB Target group
resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


resource "aws_security_group" "instance" {
  name   = "${var.cluster_name}-example-instance"
  vpc_id = "vpc-033ceae946fa9afd3"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port # var.[Var Name] 형식으로 변수를 사용할 수 있음.
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
}


# auto scailing group 구성
# 시작 템플릿과 다른, 시작 구성을 사용함.
# 요즘엔 시작 템플릿을 권장함. -> launch configuration
resource "aws_launch_configuration" "example" {
  image_id        = "ami-0f3a440bbcff3d043"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  # 이 코드는 변경할 필요가 없음. immutable system 하드코딩을 박으면 변경할게 많을 것임.
  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })


  # 얘를 설정하지 않으면, terraform이 시작 구성을 삭제하기 이전에, instance를 먼저 삭제하려 수행한다.
  # 그럼, load balancer는 이를 또 min_size를 유지하기 위해 생성을 할 것이다.
  # 이러한 이유로 먼저 시작 구성을 삭제할 수 없다.
  # 그런데 테라폼이 이를 막는지, 삭제는 되는데 계속 생성/삭제를 반복하는진 모르겠다
  # 이를 lifecycle로 해결할 수 있다.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"
  min_size             = var.min_size
  max_size             = var.max_size

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-example"
    propagate_at_launch = true
  }
}
