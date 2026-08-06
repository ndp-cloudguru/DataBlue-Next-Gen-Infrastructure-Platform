# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 4: Production Cross-Region Disaster Recovery ($10,000 – $14,800 / month)
# File: main.tf
# Description: Cấu hình mã nguồn Terraform triển khai 2 Vùng AWS (Primary Active + Secondary Pilot Light DR).
#
# Tái sử dụng các mô-đun chuẩn tại:
#   - Primary Region (us-east-1): VPC, KMS, EKS, RDS MySQL Multi-AZ, OpenSearch
#   - Secondary DR Region (us-west-2): VPC, KMS, EKS Pilot Light, RDS Cross-Region Read Replica
# ==============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  backend "s3" {
    bucket         = "datablue-prod-dr-tfstate-us-east-1"
    key            = "scenarios/scenario-4-prod-cross-region-dr/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "datablue-prod-dr-tflocks"
    encrypt        = true
  }
}

# ─── PRIMARY REGION PROVIDER (us-east-1) ────────────────────────────────────
provider "aws" {
  alias  = "primary"
  region = var.primary_region

  default_tags {
    tags = {
      Environment    = "Production-Primary"
      BusinessSystem = "DataBlue-Platform"
      Role           = "Primary-Active"
      ManagedBy      = "Terraform"
      Scenario       = "Scenario-4-Prod-Cross-Region-DR"
    }
  }
}

# ─── SECONDARY DR REGION PROVIDER (us-west-2) ───────────────────────────────
provider "aws" {
  alias  = "dr"
  region = var.secondary_region

  default_tags {
    tags = {
      Environment    = "Production-DR"
      BusinessSystem = "DataBlue-Platform"
      Role           = "Secondary-PilotLight"
      ManagedBy      = "Terraform"
      Scenario       = "Scenario-4-Prod-Cross-Region-DR"
    }
  }
}

# ==============================================================================
# 1. PRIMARY REGION (us-east-1 ACTIVE PRODUCTION STACK)
# ==============================================================================

module "kms_primary" {
  source = "../modules/kms"
  providers = {
    aws = aws.primary
  }
  environment = "Prod-Primary"
  description = "KMS Key for Primary Region us-east-1"
}

module "vpc_primary" {
  source = "../modules/vpc"
  providers = {
    aws = aws.primary
  }

  environment        = "Prod-Primary"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  database_subnet_cidrs    = ["10.0.100.0/24", "10.0.200.0/24", "10.0.300.0/24"]

  eks_cluster_name = "DataBlue-Primary-EKS"
}

module "eks_primary" {
  source = "../modules/eks"
  providers = {
    aws = aws.primary
  }

  environment     = "Prod-Primary"
  cluster_name    = "DataBlue-Primary-EKS"
  cluster_version = "1.30"

  vpc_id      = module.vpc_primary.vpc_id
  subnet_ids  = module.vpc_primary.private_app_subnet_ids
  kms_key_arn = module.kms_primary.key_arn

  node_instance_types = ["m6g.xlarge"]
  desired_size        = 6
  min_size            = 3
  max_size            = 20
  capacity_type       = "ON_DEMAND"
}

module "rds_primary" {
  source = "../modules/rds_mysql"
  providers = {
    aws = aws.primary
  }

  environment          = "Prod-Primary"
  identifier           = "databue-primary-mysql"
  vpc_id               = module.vpc_primary.vpc_id
  db_subnet_group_name = module.vpc_primary.db_subnet_group_name
  allowed_cidr_blocks  = module.vpc_primary.private_app_subnet_ids
  kms_key_arn          = module.kms_primary.key_arn

  instance_class          = "db.m6g.xlarge"
  allocated_storage       = 200
  multi_az                = true
  db_name                 = "datablue_prod_db"
  backup_retention_period = 30
}

# ==============================================================================
# 2. SECONDARY DR REGION (us-west-2 PILOT LIGHT STANDBY STACK)
# ==============================================================================

module "kms_dr" {
  source = "../modules/kms"
  providers = {
    aws = aws.dr
  }
  environment = "Prod-DR"
  description = "KMS Key for Standby DR Region us-west-2"
}

module "vpc_dr" {
  source = "../modules/vpc"
  providers = {
    aws = aws.dr
  }

  environment        = "Prod-DR"
  vpc_cidr           = "10.200.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]

  public_subnet_cidrs      = ["10.200.1.0/24", "10.200.2.0/24"]
  private_app_subnet_cidrs = ["10.200.10.0/24", "10.200.20.0/24"]
  database_subnet_cidrs    = ["10.200.100.0/24", "10.200.200.0/24"]

  eks_cluster_name = "DataBlue-StandbyDR-EKS"
}

module "eks_dr" {
  source = "../modules/eks"
  providers = {
    aws = aws.dr
  }

  environment     = "Prod-DR"
  cluster_name    = "DataBlue-StandbyDR-EKS"
  cluster_version = "1.30"

  vpc_id      = module.vpc_dr.vpc_id
  subnet_ids  = module.vpc_dr.private_app_subnet_ids
  kms_key_arn = module.kms_dr.key_arn

  node_instance_types = ["m6g.large"]
  desired_size        = 2 # Pilot Light Standby footprint
  min_size            = 1
  max_size            = 10
  capacity_type       = "SPOT"
}

# ─── S3 BUCKETS & CROSS-REGION REPLICATION (CRR) ──────────────────────────────
resource "aws_s3_bucket" "primary_backup" {
  provider = aws.primary
  bucket   = "datablue-primary-backup-vault-us-east-1"
}

resource "aws_s3_bucket" "dr_backup" {
  provider = aws.dr
  bucket   = "datablue-dr-backup-vault-us-west-2"
}
