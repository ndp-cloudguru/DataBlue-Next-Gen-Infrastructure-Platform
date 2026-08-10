provider "aws" {
  alias               = "core"
  region              = var.region
  profile             = var.core_profile
  allowed_account_ids = [var.core_account_id]
}

provider "aws" {
  alias               = "entry"
  region              = var.region
  profile             = var.entry_profile
  allowed_account_ids = [var.entry_account_id]
}