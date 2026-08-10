data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "test/01-core-foundation/terraform.tfstate"
    region  = var.region
    profile = var.aws_profile
  }
}

module "security" {
  source    = "../../../modules/data-security"
  name      = "datablue-test"
  vpc_id    = data.terraform_remote_state.foundation.outputs.vpc_id
  app_cidrs = [data.terraform_remote_state.foundation.outputs.vpc_cidr]
  tags      = local.common_tags
}

module "rds" {
  source             = "../../../modules/rds-mysql"
  identifier         = "datablue-test-mysql"
  instance_class     = var.mysql_instance_class
  subnet_ids         = data.terraform_remote_state.foundation.outputs.database_subnet_ids
  security_group_ids = [module.security.rds_sg_id]
  kms_key_arn        = data.terraform_remote_state.foundation.outputs.kms_key_arn
  secret_name        = "datablue/test/rds-mysql"
  tags               = local.common_tags
}

module "redis" {
  source             = "../../../modules/redis"
  name               = "datablue-test-redis"
  node_type          = var.redis_node_type
  subnet_ids         = data.terraform_remote_state.foundation.outputs.database_subnet_ids
  security_group_ids = [module.security.redis_sg_id]
  kms_key_arn        = data.terraform_remote_state.foundation.outputs.kms_key_arn
  secret_name        = "datablue/test/redis"
  tags               = local.common_tags
}

module "mq" {
  source             = "../../../modules/amazon-mq"
  name               = "datablue-test-rabbitmq"
  instance_type      = var.mq_instance_type
  subnet_ids         = data.terraform_remote_state.foundation.outputs.database_subnet_ids
  security_group_ids = [module.security.mq_sg_id]
  kms_key_arn        = data.terraform_remote_state.foundation.outputs.kms_key_arn
  secret_name        = "datablue/test/rabbitmq"
  tags               = local.common_tags
}
