# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 5: Enterprise Multi-Account Isolation Architecture ($12,000 – $18,500 / month)
# File: main.tf
# Description: Cấu hình mã nguồn Terraform triển khai Landing Zone 5 Tài khoản AWS.
#
# Tái sử dụng các mô-đun chuẩn tại các Tài khoản cách ly:
#   - Account 1 (Prod Core): VPC, KMS, EKS, RDS MySQL, Redis, RabbitMQ, DocumentDB
#   - Account 2 (Prod Entry A): VPC, Public ALB Ingress, Reverse Proxy Nginx
#   - Account 3 (Prod Entry B): VPC, Public ALB Ingress, Reverse Proxy Nginx
#   - Account 4 (Dev/Test Isolated): VPC, KMS, EKS Dev, RDS Dev (100% Cách ly KO TGW)
#   - Account 5 (Shared Services): VPC, KMS, GitLab, Jenkins, ECR, OpenSearch
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
    bucket         = "datablue-landing-zone-tfstate"
    key            = "scenarios/scenario-5-enterprise-multi-account/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "datablue-landing-zone-tflocks"
    encrypt        = true
  }
}

# ─── PROVIDERS DÀNH CHO 5 TÀI KHOẢN LANDING ZONE ─────────────────────────────
provider "aws" {
  alias  = "prod_core"
  region = var.aws_region

  default_tags {
    tags = {
      Account     = "Prod-Core-Account-1"
      Environment = "Production"
      ManagedBy   = "Terraform"
      Scenario    = "Scenario-5-Multi-Account"
    }
  }
}

provider "aws" {
  alias  = "dev_test"
  region = var.aws_region

  default_tags {
    tags = {
      Account     = "Dev-Test-Account-4"
      Environment = "DevTest-Isolated"
      ManagedBy   = "Terraform"
      Scenario    = "Scenario-5-Multi-Account"
    }
  }
}

provider "aws" {
  alias  = "shared_services"
  region = var.aws_region

  default_tags {
    tags = {
      Account     = "Shared-Services-Account-5"
      Environment = "SharedServices"
      ManagedBy   = "Terraform"
      Scenario    = "Scenario-5-Multi-Account"
    }
  }
}

# ==============================================================================
# 1. ACCOUNT 1 — PRODUCTION CORE ACCOUNT ($5,200 - $8,500 / tháng)
# ==============================================================================

module "kms_prod_core" {
  source = "../modules/kms"
  providers = {
    aws = aws.prod_core
  }
  environment = "Prod-Core"
  description = "KMS CMK Key for Account 1 Prod Core"
}

module "vpc_prod_core" {
  source = "../modules/vpc"
  providers = {
    aws = aws.prod_core
  }

  environment        = "Prod-Core"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  database_subnet_cidrs    = ["10.0.100.0/24", "10.0.200.0/24", "10.0.300.0/24"]

  eks_cluster_name = "DataBlue-ProdCore-EKS"
}

module "eks_prod_core" {
  source = "../modules/eks"
  providers = {
    aws = aws.prod_core
  }

  environment     = "Prod-Core"
  cluster_name    = "DataBlue-ProdCore-EKS"
  cluster_version = "1.30"

  vpc_id      = module.vpc_prod_core.vpc_id
  subnet_ids  = module.vpc_prod_core.private_app_subnet_ids
  kms_key_arn = module.kms_prod_core.key_arn

  node_instance_types = ["m6g.xlarge"]
  desired_size        = 6
  min_size            = 3
  max_size            = 25
  capacity_type       = "ON_DEMAND"
}

module "rds_prod_core" {
  source = "../modules/rds_mysql"
  providers = {
    aws = aws.prod_core
  }

  environment          = "Prod-Core"
  identifier           = "databue-prodcore-mysql"
  vpc_id               = module.vpc_prod_core.vpc_id
  db_subnet_group_name = module.vpc_prod_core.db_subnet_group_name
  allowed_cidr_blocks  = module.vpc_prod_core.private_app_subnet_ids
  kms_key_arn          = module.kms_prod_core.key_arn

  instance_class          = "db.m6g.xlarge"
  allocated_storage       = 200
  multi_az                = true
  db_name                 = "datablue_prodcore_db"
  backup_retention_period = 30
}

# ==============================================================================
# 2. ACCOUNT 4 — DEV/TEST ISOLATED ACCOUNT ($1,600 - $2,400 / tháng - 100% CÁCH LY)
# ==============================================================================

module "kms_dev_test" {
  source = "../modules/kms"
  providers = {
    aws = aws.dev_test
  }
  environment = "DevTest-Isolated"
  description = "KMS CMK Key for Account 4 Dev/Test Isolated"
}

module "vpc_dev_test" {
  source = "../modules/vpc"
  providers = {
    aws = aws.dev_test
  }

  environment        = "DevTest-Isolated"
  vpc_cidr           = "10.100.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs      = ["10.100.1.0/24", "10.100.2.0/24"]
  private_app_subnet_cidrs = ["10.100.10.0/24", "10.100.20.0/24"]
  database_subnet_cidrs    = ["10.100.100.0/24", "10.100.200.0/24"]

  eks_cluster_name = "DataBlue-DevTest-EKS"
}

module "eks_dev_test" {
  source = "../modules/eks"
  providers = {
    aws = aws.dev_test
  }

  environment     = "DevTest-Isolated"
  cluster_name    = "DataBlue-DevTest-EKS"
  cluster_version = "1.30"

  vpc_id      = module.vpc_dev_test.vpc_id
  subnet_ids  = module.vpc_dev_test.private_app_subnet_ids
  kms_key_arn = module.kms_dev_test.key_arn

  node_instance_types = ["m6g.large"]
  desired_size        = 2
  min_size            = 2
  max_size            = 8
  capacity_type       = "SPOT"
}

# ==============================================================================
# 3. CENTRAL TRANSIT GATEWAY HUB (Connects Accounts 1, 2, 3 only - PROHIBITS Account 4 DevTest)
# ==============================================================================
resource "aws_ec2_transit_gateway" "tgw_hub" {
  provider    = aws.prod_core
  description = "Central AWS Transit Gateway Hub connecting Prod Core and Entry Proxies only"

  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"

  tags = {
    Name = "DataBlue-Enterprise-TGW-Hub"
  }
}
