output "cluster_name" {
  value = module.eks.cluster_name
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ap-south-1 --name ${module.eks.cluster_name}"
}
