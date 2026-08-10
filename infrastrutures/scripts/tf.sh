#!/usr/bin/env bash
set -euo pipefail
ACTION=${1:?action}; UNIT=${2:?UNIT}; ROOT=$(cd "$(dirname "$0")/.." && pwd); DIR="$ROOT/terraform/live/test/$UNIT"
[[ -d "$DIR" ]] || { echo "Unknown unit: $UNIT"; exit 2; }
[[ -f "$ROOT/config/accounts.env" ]] || { echo "Missing config/accounts.env"; exit 2; }
source "$ROOT/config/accounts.env"; "$ROOT/scripts/preflight.sh" "$UNIT"
cp -n "$DIR/backend.hcl.example" "$DIR/backend.hcl" 2>/dev/null || true
sed -i.bak "s/datablue-tfstate-ap-southeast-1-REPLACE-ME/$TF_STATE_BUCKET/g" "$DIR/backend.hcl"
sed -i.bak2 "s/datablue-test-tflocks/$TF_LOCK_TABLE/g" "$DIR/backend.hcl"
rm -f "$DIR/backend.hcl.bak" "$DIR/backend.hcl.bak2"
case "$UNIT" in
  01-*|02-*|03-*) ACCOUNT_ARGS=(-var="aws_account_id=$CORE_ACCOUNT_ID");;
  04-*) ACCOUNT_ARGS=(-var="aws_account_id=$ENTRY_ACCOUNT_ID");;
  05-*) ACCOUNT_ARGS=(-var="core_account_id=$CORE_ACCOUNT_ID" -var="entry_account_id=$ENTRY_ACCOUNT_ID");;
esac
[[ "$UNIT" == 02-* || "$UNIT" == 03-* || "$UNIT" == 05-* ]] && ACCOUNT_ARGS+=( -var="state_bucket=$TF_STATE_BUCKET" )
cd "$DIR"
case "$ACTION" in
 init) terraform init -reconfigure -backend-config=backend.hcl;;
 validate) terraform fmt -check; terraform validate;;
 plan) terraform fmt -check; terraform validate; terraform plan "${ACCOUNT_ARGS[@]}" -out=tfplan;;
 apply) [[ -f tfplan ]] || { echo "No saved tfplan. Run make plan UNIT=$UNIT first."; exit 4; }; terraform apply tfplan; rm -f tfplan;;
 output) terraform output;;
 destroy) if [[ "$UNIT" == "02-core-data" && "${ALLOW_DATA_DESTROY:-NO}" != "YES" ]]; then echo "Data destroy blocked. Set ALLOW_DATA_DESTROY=YES only for intentional teardown."; exit 5; fi; terraform plan -destroy "${ACCOUNT_ARGS[@]}" -out=tfplan-destroy; echo "Destroy plan created only. Review then run: cd $DIR && terraform apply tfplan-destroy";;
 *) echo "Unknown action $ACTION"; exit 2;;
esac
