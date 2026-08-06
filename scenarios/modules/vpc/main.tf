# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Terraform Module: VPC (Networking & Subnet Topology)
# File: main.tf
# Description: Production 3-Tier VPC Networking Configuration (Public, Private App, Isolated DB).
# Architecture Ref: ADR-001 (Account Strategy), ADR-002 (Isolation), SEC-002 (Subnet Boundary)
# ==============================================================================

# 1. Main VPC with DNS Hostnames enabled for PrivateLink & EKS resolution
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-VPC"
    }
  )
}

# 2. Internet Gateway for Public Ingress and NAT Gateway Egress
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-IGW"
    }
  )
}

# 3. Public Subnets (Dedicated for Public Application Load Balancers and NAT Gateways)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name                                            = "DataBlue-${var.environment}-Public-Subnet-${count.index + 1}"
      "kubernetes.io/role/elb"                        = "1" # AWS Load Balancer Controller Public ALB Discovery Tag
      "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    }
  )
}

# 4. Private Application Subnets (Dedicated for EKS Worker Nodes, Pods, Nacos, OpenSearch)
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name                                            = "DataBlue-${var.environment}-Private-App-Subnet-${count.index + 1}"
      "kubernetes.io/role/internal-elb"               = "1"                  # Internal ALB Discovery Tag
      "karpenter.sh/discovery"                        = var.eks_cluster_name # Karpenter JIT Autoscaler Subnet Discovery Tag
      "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    }
  )
}

# 5. Isolated Database Subnets (Dedicated for RDS MySQL, Redis, RabbitMQ, DocumentDB - ZERO Internet Routes)
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-Database-Subnet-${count.index + 1}"
      Tier = "Isolated-Stateful-DB"
    }
  )
}

# 6. Elastic IPs for NAT Gateways (1 EIP per AZ for High Availability)
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-NAT-EIP-${count.index + 1}"
    }
  )
}

# 7. NAT Gateways (Deployed in Public Subnet per AZ)
resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-NAT-GW-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# 8. Route Table for Public Subnets (Routes 0.0.0.0/0 to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-Public-RT"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 9. Route Tables for Private App Subnets (Routes 0.0.0.0/0 via NAT Gateway of respective AZ)
resource "aws_route_table" "private_app" {
  count  = length(aws_subnet.private_app)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-Private-App-RT-${count.index + 1}"
    }
  )
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# 10. Isolated Route Table for Database Subnets (NO Internet or NAT Routes - Strict SEC-002 Conformance)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-Database-Isolated-RT"
    }
  )
}

resource "aws_route_table_association" "database" {
  count          = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# 11. Database Subnet Group for RDS MySQL / DocumentDB / ElastiCache
resource "aws_db_subnet_group" "this" {
  count      = length(var.database_subnet_cidrs) > 0 ? 1 : 0
  name       = "databue-${lower(var.environment)}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    var.tags,
    {
      Name = "DataBlue-${var.environment}-DB-Subnet-Group"
    }
  )
}
