provider  "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "terraform_state"{
    bucket = "terraform-state-cloudwave-bruh"
    # 얘는 global scope로 이름을 고유하게 지어야함
    lifecycle{
        prevent_destroy = true # 수동으로 삭제해라. 상태를 저장할 것임.
    }
}

# file update 마다 버전이 생성됨. 버전관리 시스템
# 이전 버전으로 되돌릴 수 있음.
resource "aws_s3_bucket_versioning" "enabled" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration{
        status = "Enabled"
    }
}

#Enable server-side encryption by default
# S3에 접근되는 모든 객체가 암호화됨, 이를 key를 통해 복호화하여 확인해야함.
# server-side이기 때문에 이를 KMS가 관리함.
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state.id
    rule{
        apply_server_side_encryption_by_default{
            sse_algorithm = "AES256"
        }
    }
}
# 모든 퍼블릭 접근을 차단한다.
# ACL 등을 적용하여 특정 사용자만 접근할 수 있게 만들 수 있다.
# 또는 policy를 사용하여 퍼블릭 접근을 막을 수 있다.
# policy를 사용하는 것을 권장한다. 
# policy를 json 형식으로 넣을 수 있다.
resource "aws_s3_bucket_public_access_block" "public_access"{
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

# s3에 접근하기 위한 분산 키값을 DynamoDB를 저장한다.
# 키를 호출하면 바로 값을 받아올 수 있다.
# 좀 더 공부하자.

resource "aws_dynamodb_table" "terraform_locks"{
    name = "terraform-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
      name = "LockID"
      type = "S"
    }
}

# 백엔드 구성할 수 있다.
# s3에 상태 파일을 저장할 수 있다.
# backend는 terraform init을 무조건 실행해줘야 한다.


terraform {
 backend "s3" {
   bucket = "terraform-state-cloudwave-bruh"
   key = "global/s3/terraform.tfstate"
   region = "ap-northeast-2"
   dynamodb_table = "terraform-locks" 
   encrypt = true
 }
}