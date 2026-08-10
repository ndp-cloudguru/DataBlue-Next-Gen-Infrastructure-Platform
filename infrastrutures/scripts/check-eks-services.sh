#!/usr/bin/env bash

# ==============================================================================
# XianZhu S2B2C - EKS Health & Service Inspection Script
# Usage: ./scripts/check-eks-services.sh
# ==============================================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

NAMESPACE="datablue-test"

echo -e "${BOLD}${CYAN}"
echo "========================================================================"
echo " 🚀 XIANZHU S2B2C - EKS HEALTH CHECK DASHBOARD"
echo "========================================================================"
echo -e "${NC}"

# 1. EKS Nodes Status
echo -e "${BOLD}1. EKS CLUSTER NODES (${NAMESPACE})${NC}"
echo "------------------------------------------------------------------------"
kubectl get nodes -o custom-columns="NODE_NAME:.metadata.name,STATUS:.status.conditions[?(@.type=='Ready')].status,INTERNAL_IP:.status.addresses[?(@.type=='InternalIP')].address,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory" | awk 'NR==1 {print $0} NR>1 {if ($2=="True") print "\033[0;32m✔ " $0 "\033[0m"; else print "\033[0;31m✖ " $0 "\033[0m"}'
echo ""

# 2. Kubernetes Pods Status
echo -e "${BOLD}2. KUBERNETES PODS & HEALTH STATUS (${NAMESPACE})${NC}"
echo "------------------------------------------------------------------------"
kubectl get pods -n "$NAMESPACE" -o custom-columns="POD_NAME:.metadata.name,READY:.status.containerStatuses[0].ready,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp" | awk '
NR==1 { printf "%-45s %-8s %-12s %-10s\n", $1, $2, $3, $4 }
NR>1 {
  status_icon = "\033[0;32m✔\033[0m"
  if ($2 != "true" || $3 != "Running") {
    status_icon = "\033[0;31m✖\033[0m"
  }
  printf "%s %-43s %-8s %-12s %-10s\n", status_icon, $1, $2, $3, $4
}'
echo ""

# 3. Active K8s Endpoints
echo -e "${BOLD}3. SERVICE ENDPOINTS (${NAMESPACE})${NC}"
echo "------------------------------------------------------------------------"
kubectl get endpoints -n "$NAMESPACE" -o custom-columns="SERVICE_NAME:.metadata.name,ENDPOINTS:.subsets[*].addresses[*].ip" | awk '
NR==1 { printf "%-40s %-40s\n", $1, $2 }
NR>1 {
  icon = "\033[0;32m🟢\033[0m"
  if ($2 == "<none>" || $2 == "") {
    icon = "\033[1;33m🟡\033[0m"
  }
  printf "%s %-38s %-40s\n", icon, $1, $2
}'
echo ""

# 4. Nacos Registered Services
echo -e "${BOLD}4. NACOS REGISTERED MICROSERVICES (Namespace: middle)${NC}"
echo "------------------------------------------------------------------------"
TOKEN=$(kubectl exec nacos-0 -n "$NAMESPACE" -- curl -s -X POST 'http://127.0.0.1:8848/nacos/v1/auth/login' -d 'username=nacos&password=nacos' 2>/dev/null | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4 || true)

if [ -n "$TOKEN" ]; then
  NACOS_SVCS=$(kubectl exec nacos-0 -n "$NAMESPACE" -- curl -s "http://127.0.0.1:8848/nacos/v1/ns/service/list?pageNo=1&pageSize=100&namespaceId=middle&accessToken=$TOKEN" 2>/dev/null | grep -o '"doms":\[[^]]*\]' || true)
  if [ -n "$NACOS_SVCS" ]; then
    echo -e "Registered Services in Nacos: ${GREEN}${NACOS_SVCS}${NC}"
  else
    echo -e "${YELLOW}⚠️ Nacos query returned empty service list or middle namespace not populated yet.${NC}"
  fi
else
  echo -e "${RED}✖ Failed to authenticate with Nacos API.${NC}"
fi

echo -e "${BOLD}${CYAN}"
echo "========================================================================"
echo " 🎉 HEALTH CHECK COMPLETED"
echo "========================================================================"
echo -e "${NC}"
