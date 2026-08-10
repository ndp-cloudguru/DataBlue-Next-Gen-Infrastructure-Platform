# Production Infrastructure Environment (`terraform/live/prod`)

This directory provides the production environment deployment configurations leveraging the modular, reusable modules defined in `terraform/modules/`.

## Architecture & State Isolation

Following the AADD Governance specification (`AGENTS.md`):

1. **Remote State Keys**:
   - `01-core-foundation`: `prod/01-core-foundation/terraform.tfstate`
   - `02-core-data`: `prod/02-core-data/terraform.tfstate`
   - `03-core-compute-runtime`: `prod/03-core-compute-runtime/terraform.tfstate`
   - `04-entry-foundation-runtime`: `prod/04-entry-foundation-runtime/terraform.tfstate`
   - `05-cross-account-connectivity`: `prod/05-cross-account-connectivity/terraform.tfstate`

2. **Production Multi-AZ & HA Overrides**:
   - `environment`: `"prod"`
   - `rds-mysql`: `multi_az = true`, `backup_retention_days = 30`, `instance_class = "db.m6g.large"`
   - `redis`: `automatic_failover_enabled = true`, `num_cache_clusters = 2`
   - `eks`: `min_size = 3`, `max_size = 10`, `desired_size = 3`
