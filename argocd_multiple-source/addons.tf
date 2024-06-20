# #---------------------------------------------------------------
# # EKS Common Addon
# https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
# https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest
# #---------------------------------------------------------------

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.3"

  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
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
  enable_metrics_server               = true
  enable_cluster_autoscaler           = true
  # enable_cluster_proportional_autoscaler = true

  # Optional Addons
  enable_aws_efs_csi_driver = false

  enable_external_dns = true
  external_dns = {
    name          = "external-dns"
    chart_version = "1.14.5"
    repository    = "https://kubernetes-sigs.github.io/external-dns/"
    namespace     = "external-dns"
    values = [templatefile("./helm_values/external_dns-value.yaml", {
      txtOwnerId = local.name
    })]
  }
  ## 없으면 IRSA안되서 access deny남
  external_dns_route53_zone_arns = [data.aws_route53_zone.environmentDomain.arn]

  tags = local.tags
}
data "aws_route53_zone" "environmentDomain" {
  zone_id = "Z05565003M3CKLMPQUTQ8"
}