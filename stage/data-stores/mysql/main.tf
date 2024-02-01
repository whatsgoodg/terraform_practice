provider "aws" {
  region = "ap-northeast-2"
}

terraform {
 backend "s3" {
 # Replace this with your bucket name!
 bucket = "terraform-state-cloudwave-bruh"
 key = "stage/data-stores/mysql/terraform.tfstate"
 region = "ap-northeast-2"
 # Replace this with your DynamoDB table name!
 dynamodb_table = "terraform-locks"
 encrypt = true
 }
}

resource "aws_db_subnet_group" "default" {
  name       = "example-subnets"
  #["subnet-045f18b2ad7211482", "subnet-0c5007db0b367d36c"]
  subnet_ids = data.aws_subnets.default.ids 
  tags = {
    Name = "example-rds"
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-mysql"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  skip_final_snapshot = true
  db_name             = "example_database"
  db_subnet_group_name = aws_db_subnet_group.default.name

  # username password configuration
  username = var.db_username
  password = var.db_password
}
