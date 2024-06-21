# 요구되는 테라폼 제공자 목록
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.21"
    }
  }
}

locals {
  name       = "haedalwang"
  region     = "ap-northeast-2"
  account_id = data.aws_caller_identity.current.account_id
  project    = "ptspro"
  env        = "dev"
  nodegroups = [
    {
      name           = "work"
      instance_types = ["t3.medium"]
    }
  ]

  tags = {
    Terraform = "true"
  }
}

# Terraform을 실행한 AWS 자격증명 정보 받아오기
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "azs" {}