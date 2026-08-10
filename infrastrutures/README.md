# DataBlue AADD Terraform AWS — Test/UAT

AADD-oriented Terraform workspace for the Test/UAT baseline in `ap-southeast-1`.

## Frozen execution order

1. `01-core-foundation` — Account 1 / `datablue-test-core`
2. `02-core-data` — Account 1 / `datablue-test-core`
3. `03-core-compute-runtime` — Account 1 / `datablue-test-core`
4. `04-entry-foundation-runtime` — Account 4 / `datablue-test-entry`
5. `05-cross-account-connectivity` — Account 1 + Account 4 only

Account 1 is completed first. Account 4 is then built independently. Direct VPC Peering and cross-VPC rules are created only in phase 05. Test does **not** use Transit Gateway.

## Quick start

```bash
cp config/accounts.example.env config/accounts.env
# edit real account IDs / profiles
./scripts/bootstrap-backend.sh
./scripts/preflight.sh 01-core-foundation
make init UNIT=01-core-foundation
make validate UNIT=01-core-foundation
make plan UNIT=01-core-foundation
make apply UNIT=01-core-foundation
```

Continue phases in numeric order. See `docs/05-operations/OPERATIONS-RUNBOOK.md`.

> Terraform code is intentionally split into separate states. Never run `terraform apply` from `terraform/live/test` itself.

## Antigravity one-task execution

The repository includes an `.agent/` execution layer. In Antigravity, run workflows in order:

`/preflight` -> `/core-foundation` -> `/core-data` -> `/core-compute-runtime` -> `/entry-foundation-runtime` -> `/cross-account-connectivity` -> `/verify-environment`.

Each phase performs its own preflight, Terraform validation, saved plan, boundary guard, apply, outputs and execution report. See `.agent/README.md`.

### Bootstrap Terraform Backend

Before the first Terraform phase, configure `config/accounts.env` and run:

```bash
make bootstrap-backend
```

This creates/verifies the remote S3 state bucket and DynamoDB lock table in Account 1. The command is idempotent and safe to rerun.
