variable "namespace" {
  description = "Namespace for k8s-inspector deployment"
  type        = string
  default     = "k8s-inspector"
}

variable "chart_version" {
  description = "Version of the k8sinspector Helm chart"
  type        = string
  default     = null # Uses latest if not specified
}

variable "image_tag" {
  description = "Tag for the k8s-inspector container image"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of replicas for k8s-inspector"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "allowed_ips" {
  description = "List of allowed IP addresses/CIDR blocks to access k8s-inspector ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster (for allowing ALB to reach pods)"
  type        = string
}
