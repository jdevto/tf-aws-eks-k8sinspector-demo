variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "cluster_name" {
  type    = string
  default = "test"
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "k8s_inspector_chart_version" {
  description = "Version of the k8sinspector Helm chart"
  type        = string
  default     = null # Uses latest if not specified
}

variable "k8s_inspector_image_tag" {
  description = "Tag for the k8s-inspector container image"
  type        = string
  default     = "latest"
}

variable "k8s_inspector_replicas" {
  description = "Number of replicas for k8s-inspector"
  type        = number
  default     = 2
}

variable "k8s_inspector_namespace" {
  description = "Namespace for k8s-inspector deployment"
  type        = string
  default     = "k8s-inspector"
}

variable "k8s_inspector_allowed_ips" {
  description = "List of allowed IP addresses/CIDR blocks to access k8s-inspector ALB. If empty, allows all IPs."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
