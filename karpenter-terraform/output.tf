output "configure_kubectl" {
  description = "Configure kubectl: "
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "karpenter_nodeclass_role" {
  description = "ec2class.yaml spec.role:  "
  value       = "${module.karpenter.node_iam_role_name}"
}


