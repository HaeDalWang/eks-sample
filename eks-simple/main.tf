#---------------------------------------------------------------
# 프로바이더 및 로컬 변수 지정, 백엔드 지정
#---------------------------------------------------------------

provider "aws" {
  region = local.region
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# 생성되는 클러스터의 권한
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

locals {
  name = "seungdo-eks"
  region       = "ap-northeast-2"

  tags = {
    Name      = "Seungdo"
    Terraform = "true"
  }
}

# 백엔드 설정 
# terraform {
#   backend "s3" {
#     bucket         = "seungdo-s3-tfstate"
#     key            = "eks/terraform.tfstate"
#     region         = "ap-northeast-2"
#     dynamodb_table = "TerraformStateLock"
#     encrypt        = true
#   }
# }