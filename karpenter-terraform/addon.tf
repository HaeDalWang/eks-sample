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
      # https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/main/examples/stateful/main.tf
      # service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  # Common Addons
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }
  enable_metrics_server               = true

  ## 클러스터 오토 스케일러 대신 Karpenter 사용
  # enable_cluster_autoscaler           = true
  enable_karpenter                           = true
  karpenter_enable_instance_profile_creation = true
  # ECR login required
  karpenter = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }

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
data "aws_route53_zone" "environmentDomain" {
  name = "${local.cluster_root_domain}"
}