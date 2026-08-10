data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket  = var.state_bucket
    key     = "test/01-core-foundation/terraform.tfstate"
    region  = var.region
    profile = var.aws_profile
  }
}

module "eks" {
  source          = "../../../modules/eks"
  cluster_name    = "datablue-test-eks"
  cluster_version = var.cluster_version
  instance_type   = var.eks_node_instance_type
  min_size        = var.eks_min_size
  max_size        = var.eks_max_size
  desired_size    = var.eks_desired_size
  vpc_id          = data.terraform_remote_state.foundation.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.foundation.outputs.private_app_subnet_ids
  kms_key_arn     = data.terraform_remote_state.foundation.outputs.kms_key_arn
  tags            = local.common_tags
}

# Generic App Core IRSA Role for backend microservices in namespace datablue-test
module "app_core_irsa" {
  source                    = "../../../modules/iam-irsa"
  role_name                 = "datablue-test-app-core-irsa-role"
  oidc_provider_arn         = module.eks.oidc_provider_arn
  oidc_issuer_url           = module.eks.cluster_oidc_issuer_url
  service_account_namespace = "datablue-test"
  service_account_name      = "app-core-sa"
  tags                      = local.common_tags
}
