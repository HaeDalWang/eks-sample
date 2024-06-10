# #---------------------------------------------------------------
# # EKS Common Addon
# https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
# https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest
# #---------------------------------------------------------------

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Common Addons
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [{
      # https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html
      # 기본 service 리소스 생성 시 ELB 타입을 결정
      # false의 경우 Claiic LB 생성, true면 NLB 생성
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }
  enable_metrics_server = true

  # 클러스터 오토 스케일러 대신 Karpenter 사용
  enable_cluster_autoscaler           = true
  # enable_karpenter                           = true
  # # 카펜터가 spot을 종료가능
  # karpenter_enable_spot_termination          = true
  # # 카펜터가 인스턴스 IAM생성 가능
  # karpenter_enable_instance_profile_creation = true
  # # 확인 필요
  # karpenter_node = {
  #   iam_role_use_name_prefix = false
  # }
  # 카펜터 container 이미지가 버지니아에 있음
  # karpenter = {
  #   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #   repository_password = data.aws_ecrpublic_authorization_token.token.password
  # }

  enable_external_dns = true
  external_dns = {
    name          = "external-dns"
    chart_version = "1.14.4"
    repository    = "https://kubernetes-sigs.github.io/external-dns/"
    namespace     = "external-dns"
    values = [templatefile("./helm_values/external_dns-value.yaml", {
      txtOwnerId    = local.name
      domainFilters = local.cluster_root_domain
    })]
  }
  ## IRSA 진행 조건, data는 아래
  external_dns_route53_zone_arns = [data.aws_route53_zone.environmentDomain.arn]

  tags = local.tags
}
# Route53 에서 사용할 도메인 불러오기
data "aws_route53_zone" "environmentDomain" {
  name = local.cluster_root_domain
}

# aws-auth configmap에 karpenter가 노드를 관리할 권한 추가
# module "aws-auth" {
#   source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
#   version = "~> 20.0"

#   manage_aws_auth_configmap = true

#   aws_auth_roles = [
#     {
#       rolearn  = module.eks_blueprints_addons.karpenter.node_iam_role_arn
#       username = "system:node:{{EC2PrivateDNSName}}"
#       groups   = ["system:bootstrappers","system:nodes"]
#     },
#   ]
# }

################################################################################
# Karpenter
################################################################################

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.11.1"

  cluster_name = module.eks.cluster_name

  enable_pod_identity             = true
  create_pod_identity_association = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  tags = local.tags
}

module "karpenter_disabled" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.11.1"

  create = false
}

################################################################################
# Karpenter Helm chart & manifests
# Not required; just to demonstrate functionality of the sub-module
################################################################################

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "0.36.1"
  wait                = false

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    EOT
  ]
}

## EC2 Spot 인스턴스를 프로비저닝하기 위해서 Service-linked-Role 에 대한 권한이 필요하며
## 관련 공식 문서
## https://docs.aws.amazon.com/ko_kr/IAM/latest/UserGuide/id_roles_terms-and-concepts.html
## Issue 관련 링크
## https://github.com/aws/karpenter-provider-aws/issues/5436
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}