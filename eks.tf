#---------------------------------------------------------------
# EKS 클러스터 생성
# aws 공식 EKS 모듈 사용
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
#---------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name = local.cluster_name

  cluster_version = "1.27"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_enabled_log_types       = null

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    # key == 인스턴스 이름
    sandbox = {
      # AutoSacle 범위
      min_size     = 1
      max_size     = 5
      desired_size = 2

      # 인스턴스 유형
      instance_types = ["t3.large"]
    }
  }

  tags = local.tags
}