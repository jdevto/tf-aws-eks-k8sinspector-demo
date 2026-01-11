output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "k8s_inspector_url" {
  description = "URL to access k8s-inspector application via ALB"
  value       = module.k8s_inspector.alb_url
}

output "k8s_inspector_alb_hostname" {
  description = "ALB hostname for k8s-inspector"
  value       = module.k8s_inspector.alb_hostname
}
