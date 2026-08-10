#!/usr/bin/env bash
set -euo pipefail
UNIT=${1:?usage: agent-task.sh <unit> [plan|execute]}
MODE=${2:-execute}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
RUN_DIR="$ROOT/.agent/runs/$(date +%Y-%m-%d)"
mkdir -p "$RUN_DIR"
REPORT="$RUN_DIR/${UNIT}-$(date +%H%M%S).md"

case "$UNIT" in
  01-core-foundation|02-core-data|03-core-compute-runtime|04-entry-foundation-runtime|05-cross-account-connectivity) ;;
  *) echo "Unknown unit: $UNIT"; exit 2;;
esac

{
  echo "# Execution Report — $UNIT"
  echo
  echo "- Timestamp: $(date -Iseconds)"
  echo "- Mode: $MODE"
  echo "- Git revision: $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo uncommitted)"
  echo
  echo "## Preflight"
} > "$REPORT"

if ! "$ROOT/scripts/preflight.sh" "$UNIT" 2>&1 | tee -a "$REPORT"; then
  echo -e '\nResult: **BLOCKED — preflight failed**' >> "$REPORT"
  exit 20
fi

for action in init validate plan; do
  echo -e "\n## Terraform $action" >> "$REPORT"
  if ! "$ROOT/scripts/tf.sh" "$action" "$UNIT" 2>&1 | tee -a "$REPORT"; then
    echo -e "\nResult: **FAIL — terraform $action**" >> "$REPORT"
    exit 21
  fi
done

echo -e "\n## Plan boundary guard" >> "$REPORT"
if ! "$ROOT/scripts/plan-guard.sh" "$UNIT" 2>&1 | tee -a "$REPORT"; then
  echo -e '\nResult: **BLOCKED — plan boundary guard**' >> "$REPORT"
  exit 22
fi

if [[ "$MODE" == "plan" ]]; then
  echo -e '\nResult: **PASS — plan only, no apply performed**' >> "$REPORT"
  echo "Report: $REPORT"
  exit 0
fi

[[ "$MODE" == "execute" ]] || { echo "Mode must be plan or execute"; exit 2; }

echo -e "\n## Terraform apply" >> "$REPORT"
if ! "$ROOT/scripts/tf.sh" apply "$UNIT" 2>&1 | tee -a "$REPORT"; then
  echo -e '\nResult: **FAIL — apply**' >> "$REPORT"
  exit 23
fi

echo -e "\n## Terraform outputs" >> "$REPORT"
"$ROOT/scripts/tf.sh" output "$UNIT" 2>&1 | tee -a "$REPORT" || true

echo -e '\nResult: **PASS — phase applied. Run phase-specific verification before continuing.**' >> "$REPORT"
echo "Report: $REPORT"
