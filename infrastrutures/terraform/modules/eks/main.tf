module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "~> 20.0"
  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_service_ipv4_cidr                = var.cluster_service_ipv4_cidr
  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true
  vpc_id                                   = var.vpc_id
  subnet_ids                               = var.subnet_ids
  enable_irsa                              = true
  create_cloudwatch_log_group              = false
  enable_cluster_creator_admin_permissions = true

  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = var.kms_key_arn
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.instance_type]
      ami_type       = "AL2023_ARM_64_STANDARD"
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
    }
  }

  tags = var.tags
}
