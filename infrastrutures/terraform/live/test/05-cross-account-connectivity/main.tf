data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "test/01-core-foundation/terraform.tfstate"
    region  = var.region
    profile = var.core_profile
  }
}

data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "test/03-core-compute-runtime/terraform.tfstate"
    region  = var.region
    profile = var.core_profile
  }
}

data "terraform_remote_state" "entry" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "test/04-entry-foundation-runtime/terraform.tfstate"
    region  = var.region
    profile = var.entry_profile
  }
}

resource "aws_vpc_peering_connection" "this" {
  provider      = aws.entry
  vpc_id        = data.terraform_remote_state.entry.outputs.vpc_id
  peer_vpc_id   = data.terraform_remote_state.core.outputs.vpc_id
  peer_owner_id = var.core_account_id
  peer_region   = var.region
  auto_accept   = false
  tags          = merge(local.common_tags, { Name = "datablue-test-entry-to-core" })
}

resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.core
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true
  tags                      = merge(local.common_tags, { Name = "datablue-test-entry-to-core" })
}

resource "aws_vpc_peering_connection_options" "requester" {
  provider                  = aws.entry
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  provider                  = aws.core
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "entry_to_core" {
  provider                  = aws.entry
  for_each                  = toset(data.terraform_remote_state.entry.outputs.private_route_table_ids)
  route_table_id            = each.value
  destination_cidr_block    = data.terraform_remote_state.core.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "core_to_entry" {
  provider                  = aws.core
  for_each                  = toset(data.terraform_remote_state.core.outputs.private_route_table_ids)
  route_table_id            = each.value
  destination_cidr_block    = data.terraform_remote_state.entry.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_security_group_rule" "entry_to_eks" {
  provider          = aws.core
  type              = "ingress"
  from_port         = var.core_app_port
  to_port           = var.core_app_port
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.entry.outputs.vpc_cidr]
  security_group_id = data.terraform_remote_state.compute.outputs.eks_node_security_group_id
  description       = "Entry VPC proxy to EKS application port 8080"
}

resource "aws_security_group_rule" "entry_to_eks_6969" {
  provider          = aws.core
  type              = "ingress"
  from_port         = 6969
  to_port           = 6969
  protocol          = "tcp"
  cidr_blocks       = [data.terraform_remote_state.entry.outputs.vpc_cidr]
  security_group_id = data.terraform_remote_state.compute.outputs.eks_node_security_group_id
  description       = "Entry VPC proxy to EKS data checker port 6969"
}
