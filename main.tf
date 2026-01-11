# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name               = var.cluster_name
  cluster_name       = var.cluster_name
  availability_zones = ["${var.region}a", "${var.region}b"]

  tags = merge(local.common_tags, {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version # Cluster control plane can use both public and private subnets
  subnet_ids      = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  # Node groups should be in private subnets only for security
  node_subnet_ids = module.vpc.private_subnet_ids
  vpc_id          = module.vpc.vpc_id
  tags            = local.common_tags
}

# k8s-inspector Module
module "k8s_inspector" {
  source = "./modules/k8s-inspector"

  namespace                 = var.k8s_inspector_namespace
  chart_version             = var.k8s_inspector_chart_version
  image_tag                 = var.k8s_inspector_image_tag
  replicas                  = var.k8s_inspector_replicas
  vpc_id                    = module.vpc.vpc_id
  allowed_ips               = var.k8s_inspector_allowed_ips
  cluster_security_group_id = module.eks.cluster_security_group_id
  tags                      = local.common_tags

  depends_on = [module.eks, module.vpc]
}
