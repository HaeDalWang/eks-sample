#---------------------------------------------------------------
# 프로바이더 및 로컬 변수 지정
#---------------------------------------------------------------

provider "aws" {
  region = local.region
}
# Karpenter 컨테이너가 ECR 퍼블릭에 존재 해당 컨테이너를 리전에 맞도록 가져오기 위해 필요
# 컨테이너 이름에 리전이 들어감
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
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

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# 퍼블릭 ECR에 로그인하여 다운받기 위해 토큰으로 접근
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

locals {
  name = "eks-sample-karpenter"

  # Route53 root Domain
  cluster_root_domain = var.route53_domain
  region              = "ap-northeast-2"

  tags = {
    Environment = "test"
    Terraform   = "true"
  }
}