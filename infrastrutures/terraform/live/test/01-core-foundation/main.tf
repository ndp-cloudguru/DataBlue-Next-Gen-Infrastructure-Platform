module "vpc" {
  source              = "../../../modules/vpc"
  name                = "datablue-test-core"
  cidr                = "10.50.0.0/16"
  azs                 = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnets      = ["10.50.1.0/24", "10.50.2.0/24"]
  private_app_subnets = ["10.50.10.0/24", "10.50.20.0/24"]
  database_subnets    = ["10.50.100.0/24", "10.50.200.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = false
  tags                = local.common_tags
}

module "kms" {
  source      = "../../../modules/kms"
  alias       = "datablue-test"
  description = "DataBlue Test shared CMK"
  tags        = local.common_tags
}

module "ecr" {
  source       = "../../../modules/ecr"
  repositories = ["datablue-test/backend-api", "datablue-test/envoy-proxy", "datablue-test/frontend"]
  kms_key_arn  = module.kms.key_arn
  tags         = local.common_tags
}
