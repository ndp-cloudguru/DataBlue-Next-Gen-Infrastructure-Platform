# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 3: Production Enhanced High Availability ($7,200 – $10,500 / month)
# File: main.tf
# Description: Triển khai cấu hình Scenario 3 High-Scale HA tái sử dụng các mô-đun chuẩn.
#
# Kiến trúc bao gồm:
#   - VPC 3-AZ High-Scale
#   - AWS KMS Customer Managed Key (CMK)
#   - EKS v1.30+ Cluster (~28 Nodes r6g.xlarge / c6g.2xlarge mix)
#   - Amazon Aurora MySQL 3 Replicas Cluster (db.r6g.xlarge)
#   - ElastiCache Redis Sharded Cluster 6-Node (cache.m6g.large)
#   - Amazon MQ RabbitMQ 3-Node Broker (mq.m6g.xlarge)
#   - Amazon DocumentDB 3-Node Cluster (db.r6g.2xlarge)
#   - Amazon OpenSearch 4-Node Cluster (r6g.large.search)
# ==============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "datablue-prod-ha-tfstate-us-east-1"
    key            = "scenarios/scenario-3-prod-high-scale-ha/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "datablue-prod-ha-tflocks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment    = "Production-HA"
      BusinessSystem = "DataBlue-Platform"
      CostCenter     = "CC-301-PROD-HA"
      Owner          = "SRE-DevSecOps-Team"
      ManagedBy      = "Terraform"
      Scenario       = "Scenario-3-Prod-High-Scale-HA"
    }
  }
}

# ─── TÁI SỬ DỤNG MODULE 1: AWS KMS CMK ────────────────────────────────────────
module "kms" {
  source      = "../modules/kms"
  environment = "Production-HA"
  description = "KMS Key for DataBlue Production High-Scale HA"
}

# ─── TÁI SỬ DỤNG MODULE 2: VPC NETWORKING (3 AZ High-Scale) ───────────────────
module "vpc" {
  source = "../modules/vpc"

  environment        = "Production-HA"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_app_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  database_subnet_cidrs    = ["10.0.100.0/24", "10.0.200.0/24", "10.0.300.0/24"]

  eks_cluster_name = "DataBlue-Prod-HA-EKS"
}

# ─── TÁI SỬ DỤNG MODULE 3: AMAZON EKS CLUSTER (High-Scale ~28 Nodes) ──────────
module "eks" {
  source = "../modules/eks"

  environment     = "Production-HA"
  cluster_name    = "DataBlue-Prod-HA-EKS"
  cluster_version = "1.30"

  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_app_subnet_ids
  kms_key_arn = module.kms.key_arn

  node_instance_types = ["r6g.xlarge", "c6g.2xlarge"]
  desired_size        = 12
  min_size            = 6
  max_size            = 35
  capacity_type       = "ON_DEMAND"
}

# ─── AMAZON AURORA MYSQL CLUSTER (3 Replicas High Throughput) ──────────────────
module "aurora_mysql" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.0"

  name           = "databue-aurora-mysql-cluster"
  engine         = "aurora-mysql"
  engine_version = "8.0"
  instance_class = "db.r6g.xlarge"

  instances = {
    1 = { instance_class = "db.r6g.xlarge" }
    2 = { instance_class = "db.r6g.xlarge" }
    3 = { instance_class = "db.r6g.xlarge" }
  }

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.database_subnet_ids

  master_username = "admin_aurora"
  database_name   = "datablue_prod_ha_db"

  storage_encrypted   = true
  kms_key_id          = module.kms.key_arn
  skip_final_snapshot = false
}

# ─── TÁI SỬ DỤNG MODULE 5: ELASTICACHE REDIS SHARDED (6 Nodes) ────────────────
module "elasticache_redis" {
  source = "../modules/elasticache_redis"

  environment          = "Production-HA"
  replication_group_id = "databue-prod-ha-redis"
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.database_subnet_ids
  allowed_cidr_blocks  = module.vpc.private_app_subnet_ids
  kms_key_arn          = module.kms.key_arn

  node_type          = "cache.m6g.large"
  num_cache_clusters = 6
}

# ─── TÁI SỬ DỤNG MODULE 6: AMAZON MQ RABBITMQ (mq.m6g.xlarge Broker) ─────────
module "amazon_mq_rabbitmq" {
  source = "../modules/amazon_mq_rabbitmq"

  environment         = "Production-HA"
  broker_name         = "databue-prod-ha-rabbitmq"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.database_subnet_ids
  allowed_cidr_blocks = module.vpc.private_app_subnet_ids
  kms_key_arn         = module.kms.key_arn

  host_instance_type = "mq.m6g.xlarge"
  deployment_mode    = "CLUSTER_MULTI_AZ"
}

# ─── TÁI SỬ DỤNG MODULE 7: AMAZON DOCUMENTDB (db.r6g.2xlarge 3-Node) ──────────
module "documentdb" {
  source = "../modules/documentdb"

  environment          = "Production-HA"
  cluster_identifier   = "databue-prod-ha-docdb"
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  allowed_cidr_blocks  = module.vpc.private_app_subnet_ids
  kms_key_arn          = module.kms.key_arn

  instance_class = "db.r6g.2xlarge"
  instance_count = 3
}

# ─── TÁI SỬ DỤNG MODULE 8: OPENSEARCH (4-Node High Scale Cluster) ─────────────
module "opensearch" {
  source = "../modules/opensearch"

  environment         = "Production-HA"
  domain_name         = "databue-prod-ha-opensearch"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_app_subnet_ids
  allowed_cidr_blocks = module.vpc.private_app_subnet_ids
  kms_key_arn         = module.kms.key_arn

  instance_type   = "r6g.large.search"
  instance_count  = 4
  ebs_volume_size = 500
}
