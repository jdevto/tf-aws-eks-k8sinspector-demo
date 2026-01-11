# tf-aws-eks-k8sinspector-demo

A Terraform module for deploying an Amazon EKS cluster with k8s-inspector, a Kubernetes inspection and debugging tool. This project provides a complete infrastructure setup including VPC, EKS cluster, and k8s-inspector application with ALB ingress and IP-based access control.

## Overview

This Terraform configuration deploys:

- **VPC**: A new VPC with public and private subnets across two availability zones
- **EKS Cluster**: A managed EKS cluster with node groups
- **k8s-inspector**: A Kubernetes inspection tool deployed via Helm chart with:
  - Internet-facing ALB for external access
  - IP-based access control via security groups
  - Health checks and auto-scaling
  - RBAC permissions for pod inspection

## Architecture

```text
┌─────────────────┐
│   Internet      │
└────────┬────────┘
         │
    ┌────▼────┐
    │   ALB   │ (Security Group with IP restrictions)
    └────┬────┘
         │
    ┌────▼──────────────┐
    │  EKS Cluster      │
    │  ┌──────────────┐ │
    │  │ k8s-inspector│ │
    │  │   Pods       │ │
    │  └──────────────┘ │
    └───────────────────┘
```

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured with appropriate credentials
- kubectl installed and configured
- Helm 3.x installed
- AWS Load Balancer Controller installed in the EKS cluster (handled by the EKS module)

## Quick Start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd tf-aws-eks-k8sinspector-demo
   ```

2. **Configure variables**

   Create or edit `terraform.tfvars`:

   ```hcl
   region                    = "ap-southeast-2"
   cluster_name             = "my-eks-cluster"
   cluster_version          = "1.34"
   k8s_inspector_allowed_ips = ["203.0.113.0/24", "198.51.100.0/24"]
   ```

3. **Initialize Terraform**

   ```bash
   terraform init
   ```

4. **Plan and Apply**

   ```bash
   terraform plan
   terraform apply
   ```

5. **Access k8s-inspector**

   After deployment, get the ALB URL:

   ```bash
   terraform output k8s_inspector_url
   ```

## Configuration

### Variables

| Variable | Description | Type | Default |
| -------- | ----------- | ---- | ------- |
| `region` | AWS region for resources | `string` | `"ap-southeast-2"` |
| `cluster_name` | Name of the EKS cluster | `string` | `"test"` |
| `cluster_version` | Kubernetes version for EKS | `string` | `"1.34"` |
| `k8s_inspector_namespace` | Kubernetes namespace for k8s-inspector | `string` | `"k8s-inspector"` |
| `k8s_inspector_chart_version` | Helm chart version (null = latest) | `string` | `null` |
| `k8s_inspector_image_tag` | Container image tag | `string` | `"latest"` |
| `k8s_inspector_replicas` | Number of replicas | `number` | `2` |
| `k8s_inspector_allowed_ips` | Allowed IPs/CIDRs for ALB access | `list(string)` | `["0.0.0.0/0"]` |
| `tags` | Common tags for all resources | `map(string)` | `{}` |

### IP Access Control

The `k8s_inspector_allowed_ips` variable controls which IP addresses can access the k8s-inspector ALB. This is enforced via security group rules.

**Examples:**

- Allow all IPs (default):

  ```hcl
  k8s_inspector_allowed_ips = ["0.0.0.0/0"]
  ```

- Restrict to specific IPs:

  ```hcl
  k8s_inspector_allowed_ips = ["203.0.113.1/32", "198.51.100.0/24"]
  ```

- Allow only your office network:

  ```hcl
  k8s_inspector_allowed_ips = ["203.0.113.0/24"]
  ```

## Outputs

| Output | Description |
| ------ | ----------- |
| `cluster_name` | Name of the EKS cluster |
| `cluster_endpoint` | EKS control plane endpoint |
| `k8s_inspector_url` | Full HTTP URL to access k8s-inspector |
| `k8s_inspector_alb_hostname` | ALB hostname |
| `k8s_inspector_namespace` | Kubernetes namespace where k8s-inspector is deployed |

## Modules

### VPC Module (`./modules/vpc`)

Creates a VPC with:

- Public and private subnets across two availability zones
- Internet Gateway and NAT Gateway
- Route tables and associations
- Proper tagging for EKS integration

### EKS Module (`./modules/eks`)

Deploys:

- EKS cluster with managed node groups
- AWS Load Balancer Controller
- OIDC provider for IRSA
- IAM roles and policies
- Optional EBS CSI driver

### k8s-inspector Module (`./modules/k8s-inspector`)

Deploys:

- Kubernetes namespace
- Security group for ALB with IP restrictions
- Security group rule for health checks
- Helm release for k8s-inspector
- ALB ingress configuration

## Security Features

1. **IP-based Access Control**: ALB access restricted via security groups
2. **Private Node Groups**: Worker nodes deployed in private subnets
3. **Security Group Rules**: Health check traffic allowed from ALB to pods
4. **RBAC**: k8s-inspector has limited permissions (read-only for pods, events, secrets)

## Health Checks

The ALB performs health checks on `/api/v1/health` endpoint:

- Protocol: HTTP
- Port: 8080
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 3

## Troubleshooting

### ALB Targets Unhealthy

If targets show as unhealthy:

1. **Check security groups**: Ensure the ALB security group can reach pods on port 8080

   ```bash
   # Verify security group rule exists
   aws ec2 describe-security-group-rules --filters "Name=group-id,Values=<cluster-sg-id>"
   ```

2. **Check pod status**:

   ```bash
   kubectl get pods -n k8s-inspector
   kubectl logs -n k8s-inspector <pod-name>
   ```

3. **Check ingress**:

   ```bash
   kubectl get ingress -n k8s-inspector
   kubectl describe ingress -n k8s-inspector
   ```

### Cannot Access ALB

1. **Verify IP restrictions**: Check if your IP is in the allowed list
2. **Check security group rules**: Ensure your IP is allowed on port 80
3. **Verify ALB status**: Check AWS Console for ALB health

### Get ALB Hostname

```bash
terraform output k8s_inspector_alb_hostname
```

Or from Kubernetes:

```bash
kubectl get ingress -n k8s-inspector -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will delete the entire EKS cluster and all associated resources. Make sure you have backups if needed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See [LICENSE](LICENSE) file for details.

## References

- [k8s-inspector Helm Chart](https://github.com/k8sforge/k8sinspector-chart)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
