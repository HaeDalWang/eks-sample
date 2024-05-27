#---------------------------------------------------------------
# VPC 생성
# aws 공식 vpc 모듈 사용
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"
  name    = local.name

  # 가용 영역 및 서브넷 cidr
  cidr            = "10.150.0.0/16"
  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  public_subnets  = ["10.150.10.0/24", "10.150.20.0/24", "10.150.30.0/24"]
  private_subnets = ["10.150.110.0/24", "10.150.120.0/24", "10.150.130.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  # ALB 컨트롤러 사용을 위한 필수 Tag
  # karpenter가 프로비저닝할 서브넷에 Tag (Private)
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
    "karpenter.sh/discovery"              = local.name
  }

  tags = local.tags
}

#---------------------------------------------------------------
# EKS 클러스터 생성
# aws 공식 EKS 모듈 사용
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
#---------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.10"

  cluster_name    = local.name
  cluster_version = "1.29"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources (Karpenter) into the cluster
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns                = { most_recent = true }
    eks-pod-identity-agent = {}
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
  }

  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/eks_managed_node_group/main.tf
  eks_managed_node_groups = {
    # key == 인스턴스 이름
    karpenter = {
      # cpu 아키텍처
      # ami_type = "AL3_ARM_64"
      # AutoSacle 범위
      min_size     = 1
      max_size     = 5
      desired_size = 2

      # 인스턴스 유형
      instance_types = ["t3.medium"]

      # 노드 그룹에 필요한 추가 정책 
      # 또 다른 방법으로는 IRSA을 진행하면 된다
      iam_role_additional_policies = {
        # SSM-Manger
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        # EBS-CSI-Driver
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
  # karpenter가 사용할 보안그룹에 태그 추가
  # 계정에 해당 태그를 갖는 보안 그룹은 단 하나여야 한다 
  tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })

}