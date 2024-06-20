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

  # public 서브넷 IP자동할당
  # map_public_ip_on_launch = true
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
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = local.tags
}