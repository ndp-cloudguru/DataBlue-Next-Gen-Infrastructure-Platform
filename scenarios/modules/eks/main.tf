# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: EKS (Kubernetes Control Plane & Compute Engine)
# File: main.tf
# Description: Production EKS v1.30+ Control Plane, Managed NodeGroup, IRSA OIDC, and Karpenter IAM Roles.
# Architecture Ref: ADR-003 (Kubernetes Engine), ADR-005 (Karpenter JIT), SEC-001 (Zero Static Credentials via IRSA)
# ==============================================================================

# 1. AWS Official Managed EKS Module (v20.x Compatible)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_public_access  = true # Public access for admin management
  cluster_endpoint_private_access = true # Private access for cluster node/pod communication

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Encrypt Kubernetes Secrets at rest using KMS Customer Managed Key
  create_kms_key = false
  cluster_encryption_config = {
    provider_key_arn = var.kms_key_arn
    resources        = ["secrets"]
  }

  # Enable cluster creator admin permissions for initial cluster access
  enable_cluster_creator_admin_permissions = true

  # Initial Managed NodeGroup for System Addons (CoreDNS, kube-proxy, aws-node, Karpenter)
  eks_managed_node_groups = {
    initial_system = {
      name                     = "${var.cluster_name}-initial-nodes"
      iam_role_name            = "${var.cluster_name}-sys-role"
      iam_role_use_name_prefix = false
      ami_type                 = "AL2023_ARM_64_STANDARD"
      instance_types           = var.node_instance_types
      capacity_type  = var.capacity_type

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      subnet_ids = var.subnet_ids

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            kms_key_id            = var.kms_key_arn
            delete_on_termination = true
          }
        }
      }

      tags = merge(
        var.tags,
        {
          "karpenter.sh/discovery" = var.cluster_name
        }
      )
    }
  }

  tags = var.tags
}

# 2. IAM Role & Instance Profile for Karpenter JIT Autoscaler (ADR-005)
resource "aws_iam_role" "karpenter_node" {
  name_prefix = "karpenter-node-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    }
  )
}

# Attach Required AWS Managed Policies for EKS Worker Nodes
resource "aws_iam_role_policy_attachment" "karpenter_worker" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_ecr" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name_prefix = "karpenter-node-profile-"
  role        = aws_iam_role.karpenter_node.name
}
