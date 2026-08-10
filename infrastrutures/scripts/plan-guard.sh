#!/usr/bin/env bash
set -euo pipefail
UNIT=${1:?usage: plan-guard.sh <unit>}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIR="$ROOT/terraform/live/test/$UNIT"
PLAN="$DIR/tfplan"
[[ -f "$PLAN" ]] || { echo "[guard] missing saved plan: $PLAN"; exit 2; }
cd "$DIR"
SHOW=$(terraform show -no-color "$PLAN")

fail_if_match() {
  local pattern=$1 label=$2
  if grep -Eqi "$pattern" <<<"$SHOW"; then
    echo "[guard] BLOCKED: $label detected outside allowed phase boundary"
    exit 10
  fi
}

case "$UNIT" in
  01-core-foundation)
    fail_if_match 'aws_(db_instance|elasticache|mq_broker|eks_cluster|eks_node_group|ecs_|lb|vpc_peering)' 'data/compute/entry/connectivity resource'
    ;;
  02-core-data)
    fail_if_match 'aws_(eks_cluster|eks_node_group|ecs_|lb|vpc_peering)' 'compute/entry/connectivity resource'
    ;;
  03-core-compute-runtime)
    fail_if_match 'aws_(db_instance|elasticache_replication_group|mq_broker|ecs_|vpc_peering)' 'data/entry/connectivity resource'
    ;;
  04-entry-foundation-runtime)
    fail_if_match 'aws_(db_instance|elasticache|mq_broker|eks_cluster|eks_node_group|vpc_peering)' 'core/data/connectivity resource'
    ;;
  05-cross-account-connectivity)
    fail_if_match 'aws_(db_instance|elasticache|mq_broker|eks_cluster|eks_node_group|ecs_cluster|ecs_service|ecs_task_definition|lb |lb\.|ecr_repository|kms_key)' 'workload/data/foundation resource'
    ;;
  *) echo "[guard] unknown unit: $UNIT"; exit 2;;
esac

if grep -Eq '^  # .* must be replaced|^  # .* will be destroyed' <<<"$SHOW"; then
  echo "[guard] WARNING: plan contains replacement or destruction. Agent must review and stop unless explicitly expected."
  exit 11
fi

echo "[guard] PASS: plan stays inside $UNIT boundary"
