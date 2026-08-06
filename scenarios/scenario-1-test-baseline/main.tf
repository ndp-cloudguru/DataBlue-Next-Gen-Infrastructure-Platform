# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 1: Early-Stage Test Environment Baseline ($362 – $500 / month)
# Region: Singapore (ap-southeast-1)
# File: main.tf
# Description: Terraform configuration to provision the AWS Test Environment.
#
# Architectural Highlights:
#   - Test Core VPC (10.50.0.0/16) in Account 1
#   - Test Entry VPC (10.40.0.0/16) in Account 4
#   - Direct VPC Peering connection (Bypassing Transit Gateway to save $173/mo!)
#   - AWS KMS Customer Managed Key (CMK)
#   - Amazon EKS v1.30+ Control Plane + 2x t4g.medium Worker Nodes
#   - Amazon RDS MySQL Single-AZ (db.t4g.medium + 100GB GP3)
#   - Amazon ElastiCache Redis (cache.t4g.small Single-Node)
#   - Amazon MQ RabbitMQ Broker (mq.t3.micro Single Instance)
#   - Account 4 Test Entry Public NLB + ECS Fargate Proxy Task
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

  # S3 Backend configuration for Test Environment tfstate
  backend "s3" {
    bucket         = "datablue-tfstate-ap-southeast-1"
    key            = "env/test/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "datablue-test-tflocks"
    encrypt        = true
  }
}

# Primary AWS Provider: Account 1 (Test Core Environment)
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile_core

  default_tags {
    tags = {
      Environment    = "Test-Core"
      BusinessSystem = "DataBlue-Platform"
      CostCenter     = "CC-101-TEST"
      Owner          = "SRE-DevSecOps-Team"
      ManagedBy      = "Terraform"
      Scenario       = "Scenario-1-Test-Baseline"
    }
  }
}

# Secondary AWS Provider: Account 4 (Internal Test Entry)
provider "aws" {
  alias   = "test_entry"
  region  = var.aws_region
  profile = var.aws_profile_entry

  default_tags {
    tags = {
      Environment    = "Test-Entry"
      BusinessSystem = "DataBlue-Platform"
      CostCenter     = "CC-104-TEST-ENTRY"
      Owner          = "SRE-DevSecOps-Team"
      ManagedBy      = "Terraform"
      Scenario       = "Scenario-1-Test-Baseline"
    }
  }
}


# ─── 1. AWS KMS CMK (Encryption At-Rest) ──────────────────────────────────────
module "kms" {
  source      = "../modules/kms"
  environment = "Test"
  description = "KMS Customer Managed Key for DataBlue Test Environment"
}

# ─── 1.1 ECR REPOSITORIES (Container Registry) ───────────────────────────────
module "ecr" {
  source               = "../modules/ecr"
  environment          = "Test"
  repository_names     = var.ecr_repository_names
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  kms_key_arn          = module.kms.key_arn
  max_image_count      = 10
}


# ─── 2. ACCOUNT 1: TEST CORE VPC NETWORKING (10.50.0.0/16) ────────────────────
module "test_core_vpc" {
  source = "../modules/vpc"

  environment        = "Test-Core"
  vpc_cidr           = var.test_core_vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs      = var.test_core_public_subnet_cidrs
  private_app_subnet_cidrs = var.test_core_private_app_subnet_cidrs
  database_subnet_cidrs    = var.test_core_database_subnet_cidrs

  eks_cluster_name = var.eks_cluster_name
}

# ─── 3. ACCOUNT 4: INTERNAL TEST ENTRY VPC NETWORKING (10.40.0.0/16) ──────────
module "test_entry_vpc" {
  source    = "../modules/vpc"
  providers = { aws = aws.test_entry }

  environment        = "Test-Entry"
  vpc_cidr           = var.test_entry_vpc_cidr
  availability_zones = var.availability_zones


  public_subnet_cidrs      = var.test_entry_public_subnet_cidrs
  private_app_subnet_cidrs = var.test_entry_private_app_subnet_cidrs
  database_subnet_cidrs    = var.test_entry_database_subnet_cidrs

  eks_cluster_name = "Test-Entry-Proxy"
}

# ─── 4. DIRECT VPC PEERING (ACCOUNT 4 TEST ENTRY <-> ACCOUNT 1 TEST CORE) ──────
resource "aws_vpc_peering_connection" "test_peering" {
  vpc_id      = module.test_entry_vpc.vpc_id
  peer_vpc_id = module.test_core_vpc.vpc_id
  auto_accept = true

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Test-Entry-To-Test-Core-Peering"
      Note = "Free Hourly Peering - Bypasses Transit Gateway to save $173/mo"
    }
  )
}

# Routes from Test Entry VPC (Public & Private App RTs) to Test Core CIDR (10.50.0.0/16)
resource "aws_route" "entry_public_to_core_peering" {
  route_table_id            = module.test_entry_vpc.public_route_table_id
  destination_cidr_block    = var.test_core_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.test_peering.id
}

resource "aws_route" "entry_app_to_core_peering" {
  count                     = length(module.test_entry_vpc.private_app_route_table_ids)
  route_table_id            = module.test_entry_vpc.private_app_route_table_ids[count.index]
  destination_cidr_block    = var.test_core_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.test_peering.id
}

# Return routes from Test Core VPC (Private App RTs) to Test Entry CIDR (10.40.0.0/16)
resource "aws_route" "core_app_to_entry_peering" {
  count                     = length(module.test_core_vpc.private_app_route_table_ids)
  route_table_id            = module.test_core_vpc.private_app_route_table_ids[count.index]
  destination_cidr_block    = var.test_entry_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.test_peering.id
}

# ─── 5. AMAZON EKS TEST CLUSTER (v1.30 Control Plane & 2x t4g.medium Workers) ─
module "eks" {
  source = "../modules/eks"

  environment     = "Test"
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.30"

  vpc_id      = module.test_core_vpc.vpc_id
  subnet_ids  = module.test_core_vpc.private_app_subnet_ids
  kms_key_arn = module.kms.key_arn

  node_instance_types = ["t4g.medium"]
  desired_size        = 2
  min_size            = 2
  max_size            = 4
  capacity_type       = "ON_DEMAND"
}

# ─── 6. RDS MYSQL TEST DATABASE (Single-AZ db.t4g.medium + 100GB GP3) ─────────
module "rds_mysql" {
  source = "../modules/rds_mysql"

  environment          = "Test"
  identifier           = "datablue-test-mysql"
  vpc_id               = module.test_core_vpc.vpc_id
  db_subnet_group_name = module.test_core_vpc.db_subnet_group_name
  allowed_cidr_blocks  = var.test_core_private_app_subnet_cidrs
  kms_key_arn          = module.kms.key_arn

  instance_class          = "db.t4g.medium"
  allocated_storage       = 100
  multi_az                = false # Single-AZ for Test Environment
  db_name                 = var.db_name
  admin_username          = var.admin_username
  backup_retention_period = 7
}

# ─── 7. ELASTICACHE REDIS TEST CACHE (Single Node cache.t4g.small) ────────────
module "elasticache_redis" {
  source = "../modules/elasticache_redis"

  environment          = "Test"
  replication_group_id = "datablue-test-redis"
  vpc_id               = module.test_core_vpc.vpc_id
  subnet_ids           = module.test_core_vpc.database_subnet_ids
  allowed_cidr_blocks  = var.test_core_private_app_subnet_cidrs
  kms_key_arn          = module.kms.key_arn

  node_type          = "cache.t4g.small"
  num_cache_clusters = 1 # Single Node for Test Cache
}

# ─── 8. AMAZON MQ RABBITMQ TEST (Single Instance mq.t3.micro) ─────────────────
module "amazon_mq_rabbitmq" {
  source = "../modules/amazon_mq_rabbitmq"

  environment         = "Test"
  broker_name         = "datablue-test-rabbitmq"
  vpc_id              = module.test_core_vpc.vpc_id
  subnet_ids          = [module.test_core_vpc.database_subnet_ids[0]]
  allowed_cidr_blocks = var.test_core_private_app_subnet_cidrs
  kms_key_arn         = module.kms.key_arn

  host_instance_type = "mq.t3.micro"
  deployment_mode    = "SINGLE_INSTANCE"
  admin_username     = "datablue_test_mq_admin"
}

# ─── 9. ACCOUNT 4 TEST PUBLIC ENTRY (Public NLB + ECS Fargate Proxy Task) ─────
resource "aws_lb" "test_entry_nlb" {
  name               = "DataBlue-Test-Entry-NLB"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.test_entry_vpc.public_subnet_ids

  tags = merge(
    var.tags,
    {
      Name  = "DataBlue-Test-Entry-NLB"
      Scope = "Account-4-Internal-Test-Entry"
    }
  )
}

resource "aws_lb_target_group" "fargate_proxy" {
  name        = "DataBlue-Test-Proxy-TG"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.test_entry_vpc.vpc_id

  health_check {
    protocol = "TCP"
    port     = "80"
  }

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Test-Proxy-TG"
    }
  )
}

resource "aws_lb_listener" "test_entry_http" {
  load_balancer_arn = aws_lb.test_entry_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_proxy.arn
  }
}

resource "aws_ecs_cluster" "test_entry" {
  name = "DataBlue-Test-Entry-ECS-Cluster"

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Test-Entry-ECS-Cluster"
    }
  )
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "DataBlue-Test-ECS-Execution-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Group for ECS Fargate Proxy Task
resource "aws_security_group" "fargate_proxy_sg" {
  name        = "datablue-test-fargate-proxy-sg"
  description = "Security Group for ECS Fargate Test Proxy Task"
  vpc_id      = module.test_entry_vpc.vpc_id

  ingress {
    description = "Allow inbound TCP from Test Entry Public Subnets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.test_entry_public_subnet_cidrs
  }

  egress {
    description = "Allow outbound traffic to Test Core VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Test-Fargate-Proxy-SG"
    }
  )
}

# ECS Fargate Task Definition (1 vCPU / 2GB Task per TERRAFORM_TEST_PLANNING.md)
resource "aws_ecs_task_definition" "fargate_proxy" {
  family                   = "datablue-test-proxy-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "envoy-proxy"
      image     = "envoyproxy/envoy:v1.28.0"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Test-Proxy-Task"
    }
  )
}

# ECS Fargate Service
resource "aws_ecs_service" "fargate_proxy" {
  name            = "DataBlue-Test-Entry-Proxy-Service"
  cluster         = aws_ecs_cluster.test_entry.id
  task_definition = aws_ecs_task_definition.fargate_proxy.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.test_entry_vpc.private_app_subnet_ids
    security_groups  = [aws_security_group.fargate_proxy_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_proxy.arn
    container_name   = "envoy-proxy"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.test_entry_http]

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Test-Entry-Proxy-Service"
    }
  )
}

