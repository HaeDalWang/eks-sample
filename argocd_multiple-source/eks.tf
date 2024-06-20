#---------------------------------------------------------------
# EKS 클러스터 생성
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
#---------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name = local.name

  cluster_version = "1.30"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_enabled_log_types       = null

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  # PUblic 서브넷 같이 사용 시 
  # subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  eks_managed_node_groups = {
    # key == 인스턴스 이름
    sandbox = {
      # AutoSacle 범위
      min_size     = 1
      max_size     = 5
      desired_size = 2

      # 인스턴스 유형
      instance_types = ["t3.medium"]

      # 노드 그룹에 필요한 추가 정책 
      # 또 다른 방법으로는 IRSA을 진행하면 된다
      iam_role_additional_policies = {
        # EBS-CSI-Driver
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        # SSM-Manger
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  tags = local.tags
}