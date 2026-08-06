# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# SCENARIO 2: Production Early-Start Environment ($2,096.49 / month)
# File: main.tf
# Description: Production Early-Start 3-AZ Infrastructure across Account 1 (Core),
#              Account 2 (Entry A), and Account 3 (Entry B) connected via Transit Gateway.
# Architecture Ref: TERRAFORM_PROD_EARLYSTART_PLANNING.md
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

  # S3 Backend configuration for Production Environment tfstate
  backend "s3" {
    bucket         = "datablue-tfstate-ap-southeast-1"
    key            = "env/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "datablue-prod-tflocks"
    encrypt        = true
  }
}

# ─── 0. MULTI-ACCOUNT AWS PROVIDERS (ACCOUNT 1 CORE, ACC 2 ENTRY A, ACC 3 ENTRY B) ──
# Primary Provider: Account 1 (Main Production Core)
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile_core

  default_tags {
    tags = merge(
      var.tags,
      {
        AccountRole = "Prod-Core-Account1"
      }
    )
  }
}

# Secondary Provider: Account 2 (Production Public Entry A)
provider "aws" {
  alias   = "prod_entry_a"
  region  = var.aws_region
  profile = var.aws_profile_entry_a

  default_tags {
    tags = merge(
      var.tags,
      {
        AccountRole = "Prod-EntryA-Account2"
      }
    )
  }
}

# Tertiary Provider: Account 3 (Production Public Entry B - Standby)
provider "aws" {
  alias   = "prod_entry_b"
  region  = var.aws_region
  profile = var.aws_profile_entry_b

  default_tags {
    tags = merge(
      var.tags,
      {
        AccountRole = "Prod-EntryB-Account3"
      }
    )
  }
}

# ─── 1. AWS KMS CMK (Production Encryption At-Rest) ─────────────────────────
module "kms" {
  source      = "../modules/kms"
  environment = "Production"
  description = "KMS Customer Managed Key for DataBlue Production Environment"
}

# ─── 1.1 ECR REPOSITORIES (Container Registry with IMMUTABLE Tags) ────────────
module "ecr" {
  source               = "../modules/ecr"
  environment          = "Production"
  repository_names     = var.ecr_repository_names
  image_tag_mutability = "IMMUTABLE" # IMMUTABLE tags for Production Security
  scan_on_push         = true
  kms_key_arn          = module.kms.key_arn
  max_image_count      = 20
}

# ─── 2. ACCOUNT 1: PRODUCTION CORE VPC NETWORKING (10.10.0.0/16 - 3-AZ) ──────
module "prod_core_vpc" {
  source = "../modules/vpc"

  environment        = "Prod-Core"
  vpc_cidr           = var.prod_core_vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs      = var.prod_core_public_subnet_cidrs
  private_app_subnet_cidrs = var.prod_core_private_app_subnet_cidrs
  database_subnet_cidrs    = var.prod_core_database_subnet_cidrs

  eks_cluster_name = var.eks_cluster_name
}

# ─── 3. ACCOUNT 2: PRODUCTION ENTRY VPC A (10.20.0.0/16 - 3-AZ) ──────────────
module "prod_entry_a_vpc" {
  source    = "../modules/vpc"
  providers = { aws = aws.prod_entry_a }

  environment        = "Prod-Entry-A"
  vpc_cidr           = var.prod_entry_a_vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs      = var.prod_entry_a_public_subnet_cidrs
  private_app_subnet_cidrs = var.prod_entry_a_private_app_subnet_cidrs
  database_subnet_cidrs    = []

  eks_cluster_name = "Prod-Entry-Proxy-A"
}

# ─── 4. ACCOUNT 3: PRODUCTION ENTRY VPC B (10.30.0.0/16 - 3-AZ) ──────────────
module "prod_entry_b_vpc" {
  source    = "../modules/vpc"
  providers = { aws = aws.prod_entry_b }

  environment        = "Prod-Entry-B"
  vpc_cidr           = var.prod_entry_b_vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs      = var.prod_entry_b_public_subnet_cidrs
  private_app_subnet_cidrs = var.prod_entry_b_private_app_subnet_cidrs
  database_subnet_cidrs    = []

  eks_cluster_name = "Prod-Entry-Proxy-B"
}

# ─── 5. AWS TRANSIT GATEWAY (TGW HUB CONNECTING ACCOUNT 1, 2 & 3) ──────────────
resource "aws_ec2_transit_gateway" "prod_tgw" {
  description                     = "DataBlue Production Transit Gateway Hub"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-TGW-Hub"
    }
  )
}

# TGW Attachment to Prod Core VPC (Account 1)
resource "aws_ec2_transit_gateway_vpc_attachment" "core_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.prod_tgw.id
  vpc_id             = module.prod_core_vpc.vpc_id
  subnet_ids         = module.prod_core_vpc.private_app_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-Core-TGW-Attachment"
    }
  )
}

# TGW Attachment to Entry A VPC (Account 2)
resource "aws_ec2_transit_gateway_vpc_attachment" "entry_a_tgw_attachment" {
  provider           = aws.prod_entry_a
  transit_gateway_id = aws_ec2_transit_gateway.prod_tgw.id
  vpc_id             = module.prod_entry_a_vpc.vpc_id
  subnet_ids         = module.prod_entry_a_vpc.private_app_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryA-TGW-Attachment"
    }
  )
}

# TGW Attachment to Entry B VPC (Account 3)
resource "aws_ec2_transit_gateway_vpc_attachment" "entry_b_tgw_attachment" {
  provider           = aws.prod_entry_b
  transit_gateway_id = aws_ec2_transit_gateway.prod_tgw.id
  vpc_id             = module.prod_entry_b_vpc.vpc_id
  subnet_ids         = module.prod_entry_b_vpc.private_app_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryB-TGW-Attachment"
    }
  )
}

# ─── 5.1 TRANSIT GATEWAY ROUTE TABLES & ROUTE ENTRIES ─────────────────────────
# Entry A VPC (Account 2) Private App Route Tables -> Prod Core CIDR (10.10.0.0/16) via TGW
resource "aws_route" "entry_a_to_core_tgw" {
  provider               = aws.prod_entry_a
  count                  = length(module.prod_entry_a_vpc.private_app_route_table_ids)
  route_table_id         = module.prod_entry_a_vpc.private_app_route_table_ids[count.index]
  destination_cidr_block = var.prod_core_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.prod_tgw.id
}

# Entry B VPC (Account 3) Private App Route Tables -> Prod Core CIDR (10.10.0.0/16) via TGW
resource "aws_route" "entry_b_to_core_tgw" {
  provider               = aws.prod_entry_b
  count                  = length(module.prod_entry_b_vpc.private_app_route_table_ids)
  route_table_id         = module.prod_entry_b_vpc.private_app_route_table_ids[count.index]
  destination_cidr_block = var.prod_core_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.prod_tgw.id
}

# Core VPC (Account 1) Private App Route Tables -> Entry A CIDR (10.20.0.0/16) via TGW
resource "aws_route" "core_to_entry_a_tgw" {
  count                  = length(module.prod_core_vpc.private_app_route_table_ids)
  route_table_id         = module.prod_core_vpc.private_app_route_table_ids[count.index]
  destination_cidr_block = var.prod_entry_a_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.prod_tgw.id
}

# Core VPC (Account 1) Private App Route Tables -> Entry B CIDR (10.30.0.0/16) via TGW
resource "aws_route" "core_to_entry_b_tgw" {
  count                  = length(module.prod_core_vpc.private_app_route_table_ids)
  route_table_id         = module.prod_core_vpc.private_app_route_table_ids[count.index]
  destination_cidr_block = var.prod_entry_b_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.prod_tgw.id
}


# ─── 6. EKS PRODUCTION CLUSTER (v1.30 Control Plane & 3x m7g.large Multi-AZ) ─
module "eks" {
  source = "../modules/eks"

  environment     = "Production"
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.30"

  vpc_id      = module.prod_core_vpc.vpc_id
  subnet_ids  = module.prod_core_vpc.private_app_subnet_ids
  kms_key_arn = module.kms.key_arn

  node_instance_types = var.eks_node_instance_types # m7g.large Graviton3
  desired_size        = 2                           # 2 Nodes (4 vCPUs) within current vCPU quota
  min_size            = 2
  max_size            = 6
  capacity_type       = "ON_DEMAND"
}

# ─── 7. RDS MYSQL PRODUCTION MULTI-AZ (db.t4g.xlarge 200GB GP3) ──────────────
module "rds_mysql" {
  source = "../modules/rds_mysql"

  environment          = "Production"
  identifier           = "datablue-prod-mysql"
  vpc_id               = module.prod_core_vpc.vpc_id
  db_subnet_group_name = module.prod_core_vpc.db_subnet_group_name
  allowed_cidr_blocks  = var.prod_core_private_app_subnet_cidrs
  kms_key_arn          = module.kms.key_arn

  instance_class          = "db.t4g.xlarge" # 4 vCPU / 16GB RAM
  allocated_storage       = 200             # 200GB GP3 Storage
  max_allocated_storage   = 1000
  multi_az                = true # Multi-AZ High Availability
  db_name                 = var.db_name
  admin_username          = var.admin_username
  backup_retention_period = 30 # 30-day PITR retention
}

# ─── 8. ELASTICACHE REDIS PRODUCTION 2-NODE CLUSTER (cache.t4g.large) ────────
module "elasticache_redis" {
  source = "../modules/elasticache_redis"

  environment          = "Production"
  replication_group_id = "datablue-prod-redis"
  vpc_id               = module.prod_core_vpc.vpc_id
  subnet_ids           = module.prod_core_vpc.database_subnet_ids
  allowed_cidr_blocks  = var.prod_core_private_app_subnet_cidrs
  kms_key_arn          = module.kms.key_arn

  node_type          = "cache.m6g.large" # 2 vCPU / 6.38GB RAM Graviton2 Primary/Replica
  num_cache_clusters = 2
}

# ─── 9. AMAZON MQ RABBITMQ PRODUCTION ACTIVE/STANDBY CLUSTER (mq.m5.small) ───
module "amazon_mq_rabbitmq" {
  source = "../modules/amazon_mq_rabbitmq"

  environment         = "Production"
  broker_name         = "datablue-prod-rabbitmq"
  vpc_id              = module.prod_core_vpc.vpc_id
  subnet_ids          = module.prod_core_vpc.database_subnet_ids
  allowed_cidr_blocks = var.prod_core_private_app_subnet_cidrs
  kms_key_arn         = module.kms.key_arn

  host_instance_type = "mq.m5.small" # Active/Standby Cluster
  deployment_mode    = "CLUSTER_MULTI_AZ"
  admin_username     = "admin_databue_prod_mq"
}

# ─── 10. ACCOUNT 2: PROD ENTRY A PUBLIC NLB & ECS FARGATE PROXY TASK ─────────
resource "aws_lb" "prod_entry_a_nlb" {
  provider           = aws.prod_entry_a
  name               = "DataBlue-Prod-EntryA-NLB"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.prod_entry_a_vpc.public_subnet_ids

  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryA-NLB"
    }
  )
}

resource "aws_lb_target_group" "fargate_proxy_a" {
  provider    = aws.prod_entry_a
  name        = "datablue-prod-fargate-proxy-a-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.prod_entry_a_vpc.vpc_id

  health_check {
    protocol = "TCP"
    port     = "80"
  }
}

resource "aws_lb_listener" "prod_entry_a_http" {
  provider          = aws.prod_entry_a
  load_balancer_arn = aws_lb.prod_entry_a_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_proxy_a.arn
  }
}

resource "aws_ecs_cluster" "prod_entry_a" {
  provider = aws.prod_entry_a
  name     = "DataBlue-Prod-EntryA-ECS-Cluster"

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryA-ECS-Cluster"
    }
  )
}

resource "aws_iam_role" "ecs_execution_role_a" {
  provider = aws.prod_entry_a
  name     = "DataBlue-Prod-ECS-Execution-Role-A"

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

resource "aws_iam_role_policy_attachment" "ecs_execution_policy_a" {
  provider   = aws.prod_entry_a
  role       = aws_iam_role.ecs_execution_role_a.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "fargate_proxy_sg_a" {
  provider    = aws.prod_entry_a
  name        = "datablue-prod-fargate-proxy-sg-a"
  description = "Security Group for ECS Fargate Prod Proxy Task A"
  vpc_id      = module.prod_entry_a_vpc.vpc_id

  ingress {
    description = "Allow inbound TCP from Prod Entry A Public Subnets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.prod_entry_a_public_subnet_cidrs
  }

  egress {
    description = "Allow outbound traffic via TGW"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-Fargate-Proxy-SG-A"
    }
  )
}

resource "aws_ecs_task_definition" "fargate_proxy_a" {
  provider                 = aws.prod_entry_a
  family                   = "datablue-prod-proxy-task-a"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role_a.arn

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
      Name = "DataBlue-Prod-Proxy-Task-A"
    }
  )
}

resource "aws_ecs_service" "fargate_proxy_a" {
  provider        = aws.prod_entry_a
  name            = "DataBlue-Prod-EntryA-Proxy-Service"
  cluster         = aws_ecs_cluster.prod_entry_a.id
  task_definition = aws_ecs_task_definition.fargate_proxy_a.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.prod_entry_a_vpc.private_app_subnet_ids
    security_groups  = [aws_security_group.fargate_proxy_sg_a.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_proxy_a.arn
    container_name   = "envoy-proxy"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.prod_entry_a_http]

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryA-Proxy-Service"
    }
  )
}

# ─── 11. ACCOUNT 3: PROD ENTRY B PUBLIC NLB & ECS FARGATE PROXY TASK ─────────
resource "aws_lb" "prod_entry_b_nlb" {
  provider           = aws.prod_entry_b
  name               = "DataBlue-Prod-EntryB-NLB"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.prod_entry_b_vpc.public_subnet_ids

  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryB-NLB"
    }
  )
}

resource "aws_lb_target_group" "fargate_proxy_b" {
  provider    = aws.prod_entry_b
  name        = "datablue-prod-fargate-proxy-b-tg"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.prod_entry_b_vpc.vpc_id

  health_check {
    protocol = "TCP"
    port     = "80"
  }
}

resource "aws_lb_listener" "prod_entry_b_http" {
  provider          = aws.prod_entry_b
  load_balancer_arn = aws_lb.prod_entry_b_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fargate_proxy_b.arn
  }
}

resource "aws_ecs_cluster" "prod_entry_b" {
  provider = aws.prod_entry_b
  name     = "DataBlue-Prod-EntryB-ECS-Cluster"

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryB-ECS-Cluster"
    }
  )
}

resource "aws_iam_role" "ecs_execution_role_b" {
  provider = aws.prod_entry_b
  name     = "DataBlue-Prod-ECS-Execution-Role-B"

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

resource "aws_iam_role_policy_attachment" "ecs_execution_policy_b" {
  provider   = aws.prod_entry_b
  role       = aws_iam_role.ecs_execution_role_b.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "fargate_proxy_sg_b" {
  provider    = aws.prod_entry_b
  name        = "datablue-prod-fargate-proxy-sg-b"
  description = "Security Group for ECS Fargate Prod Proxy Task B"
  vpc_id      = module.prod_entry_b_vpc.vpc_id

  ingress {
    description = "Allow inbound TCP from Prod Entry B Public Subnets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.prod_entry_b_public_subnet_cidrs
  }

  egress {
    description = "Allow outbound traffic via TGW"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-Fargate-Proxy-SG-B"
    }
  )
}

resource "aws_ecs_task_definition" "fargate_proxy_b" {
  provider                 = aws.prod_entry_b
  family                   = "datablue-prod-proxy-task-b"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role_b.arn

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
      Name = "DataBlue-Prod-Proxy-Task-B"
    }
  )
}

resource "aws_ecs_service" "fargate_proxy_b" {
  provider        = aws.prod_entry_b
  name            = "DataBlue-Prod-EntryB-Proxy-Service"
  cluster         = aws_ecs_cluster.prod_entry_b.id
  task_definition = aws_ecs_task_definition.fargate_proxy_b.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.prod_entry_b_vpc.private_app_subnet_ids
    security_groups  = [aws_security_group.fargate_proxy_sg_b.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fargate_proxy_b.arn
    container_name   = "envoy-proxy"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.prod_entry_b_http]

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-Prod-EntryB-Proxy-Service"
    }
  )
}
