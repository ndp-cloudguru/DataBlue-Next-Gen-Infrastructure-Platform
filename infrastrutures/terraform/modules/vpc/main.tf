module "vpc" {
  source                       = "terraform-aws-modules/vpc/aws"
  version                      = "~> 5.0"
  name                         = var.name
  cidr                         = var.cidr
  azs                          = var.azs
  public_subnets               = var.public_subnets
  private_subnets              = var.private_app_subnets
  database_subnets             = var.database_subnets
  create_database_subnet_group = length(var.database_subnets) > 0
  enable_nat_gateway           = var.enable_nat_gateway
  single_nat_gateway           = var.single_nat_gateway
  enable_dns_hostnames         = true
  enable_dns_support           = true
  public_subnet_tags           = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags          = { "kubernetes.io/role/internal-elb" = "1" }
  tags                         = var.tags
}
