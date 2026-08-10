#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd); source "$ROOT/config/accounts.env"
echo "== Peering =="
aws ec2 describe-vpc-peering-connections --profile "$ENTRY_PROFILE" --region "$AWS_REGION" --filters Name=status-code,Values=active --query 'VpcPeeringConnections[*].[VpcPeeringConnectionId,Status.Code]' --output table
echo "== EKS =="
aws eks describe-cluster --profile "$CORE_PROFILE" --region "$AWS_REGION" --name datablue-test-eks --query 'cluster.status' --output text
echo "== RDS =="
aws rds describe-db-instances --profile "$CORE_PROFILE" --region "$AWS_REGION" --db-instance-identifier datablue-test-mysql --query 'DBInstances[0].DBInstanceStatus' --output text
echo "== MQ =="
aws mq list-brokers --profile "$CORE_PROFILE" --region "$AWS_REGION" --query 'BrokerSummaries[*].[BrokerName,BrokerState]' --output table
echo "== ECS =="
aws ecs describe-services --profile "$ENTRY_PROFILE" --region "$AWS_REGION" --cluster datablue-test-entry-ecs-cluster --services datablue-test-entry-proxy-service --query 'services[0].[status,runningCount,pendingCount]' --output table
