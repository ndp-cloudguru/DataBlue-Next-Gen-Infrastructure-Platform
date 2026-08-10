module "vpc" {
  source              = "../../../modules/vpc"
  name                = "datablue-test-entry"
  cidr                = "10.40.0.0/16"
  azs                 = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnets      = ["10.40.1.0/24", "10.40.2.0/24"]
  private_app_subnets = ["10.40.10.0/24", "10.40.20.0/24"]
  database_subnets    = []
  enable_nat_gateway  = true
  single_nat_gateway  = true
  tags                = local.common_tags
}

module "runtime" {
  source             = "../../../modules/entry-runtime"
  name               = "datablue-test-entry"
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_app_subnet_ids
  image              = var.proxy_image
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = var.ecs_desired_count
  upstream_host      = "10.50.20.133"
  upstream_port      = 6969
  tags               = local.common_tags
}
