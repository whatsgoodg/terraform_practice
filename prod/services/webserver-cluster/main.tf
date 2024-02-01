provider "aws" {
  region = "ap-northeast-2"
}

module "webserver_cluster" {
  source                 = "../../../module/services/webserver-cluster"
  cluster_name           = "webserver-production"
  db_remote_state_bucket = "terraform-state-cloudwave"
  db_remote_state_key    = "prod/services/webserver-cluster/terraform.tfstate"
  instance_type          = "t3.micro"
  min_size               = 3
  max_size               = 3
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name  = "scale-out-during-business-hours"
  autoscaling_group_name = module.webserver_cluster.asg_name
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10 # 해당 시간대에 10개로 늘림
  recurrence             = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name  = "scale-in-at-night"
  autoscaling_group_name = module.webserver_cluster.asg_name
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-state-cloudwave-bruh"
    key    = "prod/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}