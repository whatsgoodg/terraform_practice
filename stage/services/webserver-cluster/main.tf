provider "aws" {
  region = "ap-northeast-2"
}

module "webserver_cluster" {
  source = "../../../module/services/webserver-cluster"
  # module에 선언한 변수를 여기에 설정할 수 있음.
  cluster_name           = "webserver-stage"
  db_remote_state_bucket = "terraform-state-cloudwave"
  db_remote_state_key    = "stage/services/webserver-cluster/terraform.tfstate"
  instance_type          = t3.micro
  min_size               = 2
  max_size               = 2
}

# test 용 추가 포트 노출
resource "aws_security_group_rule" "allow_testing_inbound" {
  type              = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id
  from_port         = 12345
  to_port           = 12345
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
