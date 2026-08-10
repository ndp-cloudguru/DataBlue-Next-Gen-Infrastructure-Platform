#!/usr/bin/env bash
set -euo pipefail
UNIT=${1:?usage: preflight.sh UNIT}
ROOT=$(cd "$(dirname "$0")/.." && pwd); source "$ROOT/config/accounts.env"
case "$UNIT" in
  01-core-foundation|02-core-data|03-core-compute-runtime) profiles=("$CORE_PROFILE:$CORE_ACCOUNT_ID");;
  04-entry-foundation-runtime) profiles=("$ENTRY_PROFILE:$ENTRY_ACCOUNT_ID");;
  05-cross-account-connectivity) profiles=("$CORE_PROFILE:$CORE_ACCOUNT_ID" "$ENTRY_PROFILE:$ENTRY_ACCOUNT_ID");;
  *) echo "Unknown unit $UNIT"; exit 2;;
esac
for pair in "${profiles[@]}"; do IFS=: read -r p expected <<< "$pair"; actual=$(aws sts get-caller-identity --profile "$p" --query Account --output text); [[ "$actual" == "$expected" ]] || { echo "FAIL $p expected $expected got $actual"; exit 3; }; echo "OK $p -> $actual"; done
terraform version | head -1
aws --version
echo "Preflight OK: $UNIT"
