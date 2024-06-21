module "eks" {
  source = "../module/kubernetes/eks"

  cluster_name    = "${local.project}-${local.env}"
  cluster_version = "1.28"
  vpc_id          = module.vpc.vpc_id
  vpc_subnet_ids  = module.vpc.private_subnets

  depends_on = [
    module.vpc
  ]
}

module "nodegroup" {
  source = "../module/kubernetes/eks-ng"

  count = length(local.nodegroups)

  cluster_name    = module.eks.cluster_id
  cluster_version = module.eks.cluster_version
  name            = local.nodegroups[count.index].name
  subnet_ids      = module.vpc.private_subnets

  instance_types = local.nodegroups[count.index].instance_types
  max_size       = 10
  min_size       = 2

  user_data = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex
sed -i 's/DEFAULT_CONTAINER_RUNTIME=dockerd/DEFAULT_CONTAINER_RUNTIME=containerd/' /etc/eks/bootstrap.sh

--==MYBOUNDARY==--
USERDATA

  depends_on = [
    module.vpc,
    module.eks
  ]
}

# EKS Add-on
module "eks_addon" {
  source = "../module/kubernetes/eks-addon"

  cluster_name        = module.eks.cluster_id
  cluster_version     = module.eks.cluster_version
  cluster_oidc_issuer = module.eks.cluster_oidc_provider

  depends_on = [
    module.nodegroup
  ]
}

# module "eks_common" {
#   source = "./module/kubernetes/eks-common"

#   cluster_name        = module.eks.cluster_id
#   cluster_oidc_issuer = module.eks.cluster_oidc_provider

#   public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
#   private_subnet_ids = module.private_subnets.subnet_ids

#   metric_server_chart_version                = "3.10.0"
#   cluster_autoscaler_chart_version           = "9.28.0"
#   external_dns_chart_version                 = "1.11.0"
#   aws_load_balancer_controller_chart_version = "1.5.0"
#   aws_load_balancer_controller_app_version   = "v2.5.0"
#   nginx_ingress_controller_chart_version     = "4.6.0"

#   external_dns_domain_filters = ["refinedev.io"]
#   external_dns_role_arn       = "arn:aws:iam::032559872243:role/ExternalDNSRole"
#   hostedzone_type             = "private"
#   # -new 도메인으로 추후 기존 도메인 전환시 변경 필요
#   acm_certificate_arn         = "arn:aws:acm:ap-northeast-2:008144970789:certificate/2b8e44ad-fc10-44b8-b316-36a538570dea"
#   # 기존 도메인
#   # acm_certificate_arn       = data.terraform_remote_state.common.outputs.ptspro_refinedev_io
# }