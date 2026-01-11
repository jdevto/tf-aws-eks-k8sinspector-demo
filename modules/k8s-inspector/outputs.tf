output "namespace" {
  description = "Namespace where k8s-inspector is deployed"
  value       = kubernetes_namespace.k8s_inspector.metadata[0].name
}

output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.k8s_inspector.name
}

output "release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.k8s_inspector.namespace
}

output "alb_security_group_id" {
  description = "Security group ID attached to the ALB for IP restrictions"
  value       = aws_security_group.k8s_inspector_alb.id
}

output "alb_hostname" {
  description = "ALB hostname for k8s-inspector ingress"
  value       = try(data.kubernetes_ingress_v1.k8s_inspector.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "alb_url" {
  description = "Full URL to access k8s-inspector via ALB"
  value       = try("http://${data.kubernetes_ingress_v1.k8s_inspector.status[0].load_balancer[0].ingress[0].hostname}", null)
}
