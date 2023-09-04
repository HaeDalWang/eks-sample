output "configure_kubectl" {
  description = "Configure kubectl: "
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}