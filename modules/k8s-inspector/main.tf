# Kubernetes namespace for k8s-inspector
resource "kubernetes_namespace" "k8s_inspector" {
  metadata {
    name = var.namespace
    labels = merge(
      var.tags,
      {
        "app.kubernetes.io/name"       = "k8s-inspector"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    )
  }
}

# Security group for k8s-inspector ALB
resource "aws_security_group" "k8s_inspector_alb" {
  name        = "${var.namespace}-alb-sg"
  description = "Security group for k8s-inspector ALB ingress"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_ips
    content {
      description = "Allow HTTP from ${ingress.value}"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name                           = "${var.namespace}-alb-sg"
      "app.kubernetes.io/name"       = "k8s-inspector"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "alb-security-group"
    }
  )
}

# Security group rule to allow ALB to reach pods for health checks
resource "aws_security_group_rule" "alb_to_cluster_health_check" {
  description              = "Allow ALB to reach pods on port 8080 for health checks"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k8s_inspector_alb.id
  security_group_id        = var.cluster_security_group_id
}

# k8s-inspector deployment using Helm chart
resource "helm_release" "k8s_inspector" {
  name       = "k8s-inspector"
  repository = "https://k8sforge.github.io/k8sinspector-chart"
  chart      = "k8sinspector"
  namespace  = kubernetes_namespace.k8s_inspector.metadata[0].name
  version    = var.chart_version

  # Namespace created separately
  create_namespace = false

  # Chart values
  values = [
    yamlencode({
      global = {
        enabled = true
      }
      nameOverride     = "k8s-inspector"
      fullnameOverride = "k8s-inspector"
      namespace = {
        name   = kubernetes_namespace.k8s_inspector.metadata[0].name
        create = false
      }
      image = {
        repository = "ghcr.io/platformfuzz/k8s-inspector"
        tag        = var.image_tag
        pullPolicy = "IfNotPresent"
      }
      replicaCount = var.replicas
      serviceAccount = {
        create = true
        name   = ""
      }
      rbac = {
        create = true
        rules = [
          {
            apiGroups = [""]
            resources = ["pods", "pods/log", "events", "secrets"]
            verbs     = ["get", "list"]
          }
        ]
      }
      service = {
        type       = "ClusterIP"
        port       = 80
        targetPort = 8080
      }
      ingress = {
        enabled   = true
        className = "alb"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"                       = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"                  = "ip"
          "alb.ingress.kubernetes.io/listen-ports"                 = "[{\"HTTP\": 80}]"
          "alb.ingress.kubernetes.io/healthcheck-path"             = "/api/v1/health"
          "alb.ingress.kubernetes.io/healthcheck-protocol"         = "HTTP"
          "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "30"
          "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
          "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
          "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "3"
          "alb.ingress.kubernetes.io/security-groups"              = aws_security_group.k8s_inspector_alb.id
        }
        hosts = [
          {
            host = ""
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
      }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
      livenessProbe = {
        httpGet = {
          path = "/api/v1/health"
          port = 8080
        }
        initialDelaySeconds = 10
        periodSeconds       = 30
        timeoutSeconds      = 3
        failureThreshold    = 3
      }
      readinessProbe = {
        httpGet = {
          path = "/api/v1/health"
          port = 8080
        }
        initialDelaySeconds = 5
        periodSeconds       = 10
        timeoutSeconds      = 3
        failureThreshold    = 3
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.k8s_inspector,
    aws_security_group.k8s_inspector_alb
  ]
}

# Data source to get the ingress created by Helm to extract ALB hostname
data "kubernetes_ingress_v1" "k8s_inspector" {
  metadata {
    name      = helm_release.k8s_inspector.name
    namespace = helm_release.k8s_inspector.namespace
  }

  depends_on = [helm_release.k8s_inspector]
}
