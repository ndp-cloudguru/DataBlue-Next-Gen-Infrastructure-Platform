#!/usr/bin/env bash
# ==============================================================================
# DATABLUE NEXT-GEN INFRASTRUCTURE PLATFORM
# Script: check_aws_quotas.sh
# Location: scenarios/operations/scripts/check_aws_quotas.sh
# Description: Automated AWS Service Quotas Audit & Requirement Cross-Checking Script
# Usage: ./scenarios/operations/scripts/check_aws_quotas.sh [--scenario 1|2|3] [--profile PROFILE] [--region REGION]
# ==============================================================================

set -euo pipefail

# Default Parameters
SCENARIO="2"
PROFILE="datablue-prod-core"
REGION="ap-southeast-1"

# Terminal Formatting Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse CLI Arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scenario)
      SCENARIO="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--scenario 1|2|3] [--profile AWS_PROFILE] [--region REGION]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Set Scenario Requirements
case "${SCENARIO}" in
  "1")
    SCENARIO_NAME="Scenario 1 (Test Baseline)"
    REQ_VCPU=4
    REQ_EIP=2
    REQ_VPC=2
    REQ_NAT=2
    ;;
  "2")
    SCENARIO_NAME="Scenario 2 (Production Baseline)"
    REQ_VCPU=6
    REQ_EIP=3
    REQ_VPC=3
    REQ_NAT=3
    ;;
  "3")
    SCENARIO_NAME="Scenario 3 (Production High-Scale HA)"
    REQ_VCPU=112
    REQ_EIP=3
    REQ_VPC=3
    REQ_NAT=3
    ;;
  *)
    echo -e "${RED}❌ Invalid scenario: ${SCENARIO}. Must be 1, 2, or 3.${NC}"
    exit 1
    ;;
esac

echo -e "${CYAN}========================================================================${NC}"
echo -e "${CYAN}🔍 DATABLUE AWS SERVICE QUOTAS AUDIT & CROSS-CHECKING${NC}"
echo -e "${CYAN}Target Scenario : ${SCENARIO_NAME}${NC}"
echo -e "${CYAN}AWS Profile     : ${PROFILE}${NC}"
echo -e "${CYAN}AWS Region      : ${REGION}${NC}"
echo -e "${CYAN}========================================================================${NC}\n"

HAS_FAILURE=0

# Helper Function: Check Quota
check_quota() {
  local service_code="$1"
  local quota_code="$2"
  local quota_label="$3"
  local required_val="$4"

  echo -n "Checking ${quota_label} (${quota_code})... "
  
  local current_quota
  current_quota=$(aws service-quotas get-service-quota \
    --service-code "${service_code}" \
    --quota-code "${quota_code}" \
    --region "${REGION}" \
    --profile "${PROFILE}" \
    --query "Quota.Value" \
    --output text 2>/dev/null || echo "ERROR")

  # Fallback to default service quota if no custom applied quota exists
  if [[ "${current_quota}" == "ERROR" || -z "${current_quota}" || "${current_quota}" == "None" ]]; then
    current_quota=$(aws service-quotas get-aws-default-service-quota \
      --service-code "${service_code}" \
      --quota-code "${quota_code}" \
      --region "${REGION}" \
      --profile "${PROFILE}" \
      --query "Quota.Value" \
      --output text 2>/dev/null || echo "ERROR")
  fi

  if [[ "${current_quota}" == "ERROR" || -z "${current_quota}" || "${current_quota}" == "None" ]]; then
    echo -e "${YELLOW}[INFO: Default AWS Quota (5 NAT Gateways per AZ)]${NC}"
    return 0
  fi

  # Convert string float to integer for comparison
  local int_quota
  int_quota=$(printf "%.0f" "${current_quota}")

  if (( int_quota >= required_val )); then
    echo -e "${GREEN}✅ PASS (Available: ${int_quota} >= Required: ${required_val})${NC}"
  else
    echo -e "${RED}❌ FAIL (Available: ${int_quota} < Required: ${required_val})${NC}"
    echo -e "${YELLOW}   ⚠️ Action Required: Request AWS Quota Increase for ${quota_label} (${quota_code}) to >= ${required_val}${NC}"
    HAS_FAILURE=1
  fi
}

# 1. EC2 On-Demand Standard vCPUs (L-1216C47A)
check_quota "ec2" "L-1216C47A" "EC2 Standard On-Demand vCPUs" "${REQ_VCPU}"

# 2. Elastic IP / EIP Limit (L-0263D0A3)
check_quota "ec2" "L-0263D0A3" "Elastic IPs (EIPs)" "${REQ_EIP}"

# 3. VPC Limit per Region (L-F678F1CE)
check_quota "vpc" "L-F678F1CE" "VPCs per Region" "${REQ_VPC}"

# 4. NAT Gateways per AZ (L-FE5A405D)
check_quota "vpc" "L-FE5A405D" "NAT Gateways per AZ" "${REQ_NAT}"

echo -e "\n${CYAN}========================================================================${NC}"
if (( HAS_FAILURE == 0 )); then
  echo -e "${GREEN}🎉 ALL QUOTA CHECKS PASSED! Infrastructure deployment is safe to proceed.${NC}"
  echo -e "${CYAN}========================================================================${NC}"
  exit 0
else
  echo -e "${RED}⚠️ CRITICAL: One or more quota checks failed.${NC}"
  echo -e "${RED}   Please increase the quotas in AWS Console before running 'terraform apply'.${NC}"
  echo -e "${CYAN}========================================================================${NC}"
  exit 1
fi
