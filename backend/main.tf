# 요구되는 테라폼 제공자 목록
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.15.0"
    }
  }
}

# AWS 제공자 설정
provider "aws" {
  region = "ap-northeast-2"
}

# 테라폼 상태파일 저장할 버킷 생성
# 생성 실패시 버킷이름을 바꾸자
resource "aws_s3_bucket" "terraform_state" {
  bucket = "seungdo-s3-tfstate"

  lifecycle {
    prevent_destroy = true
  }
}

# 상태 파일 복구할 경우에 대비해서 Versioning 활성화
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷에 암호화 적용
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷에 퍼블릭 접근 권한을 부여하지 못하도록 설정
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 테라폼 Lock 상태를 저장할 DynamoDB 테이블 생성
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "TerraformStateLock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}