# Infrastructure Prerequisites & Environment Preparation Guide

**Project Identifier**: `datablue-nextgen-infra-platform`  
**Governance Standard**: Architecture-First Governance Standard (`PROJECT-CHARTER.md`, `OPERATING-MODEL.md`)  
**Target Location**: `scenarios/operations/REQUIRE-PREPARE.md`

---

## 📌 Executive Overview

This document defines the mandatory **Prerequisites & Preparation Steps** required before executing any Terraform scenario (`Scenario 1` through `Scenario 5`). Completing these preparation steps ensures zero deployment blockers during Acceptance Gate audits (`GATE-00` through `GATE-02`).

---

## 1. Local Workstation Tooling Installation

Install and verify the required CLI tools on your SRE / DevSecOps administrative workstation:

| Tooling | Required Minimum Version | Verification Command | Purpose |
| :--- | :--- | :--- | :--- |
| **Terraform CLI** | `>= 1.7.0` | `terraform -version` | Infrastructure as Code provisioning engine |
| **AWS CLI** | `>= 2.15.0` | `aws --version` | AWS API & IAM Identity Center SSO authentication |
| **kubectl** | `>= 1.30.0` | `kubectl version --client` | Kubernetes cluster management & API interaction |
| **Helm** | `>= 3.14.0` | `helm version` | Kubernetes Application package manager |
| **Velero CLI** | `>= 1.13.0` | `velero version --client-only` | EKS Cluster Backup & Restore verification |
| **k6 CLI** | `>= 0.49.0` | `k6 version` | 10,000 Concurrent User Load Testing Benchmark |

---

## 2. AWS Identity & Multi-Account SSO Configuration

### 2.1 AWS IAM Identity Center (SSO) Setup
Configure AWS CLI SSO profiles for target AWS accounts (`ADR-001`):

```bash
# Configure Test Account Profile
aws configure sso --profile datablue-test

# Configure Production Core Account Profile
aws configure sso --profile datablue-prod-core

# Configure Shared Services Account Profile
aws configure sso --profile datablue-shared-services

# Authenticate session
aws sso login --profile datablue-test
```

### 2.2 AWS Service Quotas Audit & Automated Checking

Trước khi triển khai bất kỳ Scenario nào, bắt buộc thực hiện kiểm tra hạn ngạch Service Quotas trên các AWS Accounts:

#### Option 1: Chạy Script Tự động Kiểm tra Quota
```bash
# Kiểm tra Quotas cho Scenario 1 (Test Baseline)
./scenarios/operations/scripts/check_aws_quotas.sh --scenario 1 --profile datablue-test-core --region ap-southeast-1

# Kiểm tra Quotas cho Scenario 2 (Production Baseline)
./scenarios/operations/scripts/check_aws_quotas.sh --scenario 2 --profile datablue-prod-core --region ap-southeast-1

# Kiểm tra Quotas cho Scenario 3 (Production High-Scale HA)
./scenarios/operations/scripts/check_aws_quotas.sh --scenario 3 --profile datablue-prod-core --region ap-southeast-1
```

#### Option 2: Kiểm tra Quota từng Dịch vụ bằng AWS CLI
```bash
# Kiểm tra Quota vCPU On-Demand Standard (Quota Code: L-1216C47A)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region ap-southeast-1 \
  --profile datablue-prod-core

# Kiểm tra Quota Elastic IP / EIP (Quota Code: L-0263D0A3)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --region ap-southeast-1 \
  --profile datablue-prod-core
```

---

### 2.3 Hướng dẫn Yêu cầu Nâng Hạn ngạch Quota từ AWS CLI (Root / Admin Account)

Nếu kết quả kiểm tra báo thiếu Quotas (`❌ FAIL`), Quản trị viên (Root Account / Admin Profile) có thể gửi yêu cầu nâng Quotas trực tiếp qua AWS CLI mà không cần thao tác thủ công trên Console:

#### A. Gửi Yêu cầu Nâng Quota (Request Quota Increase):
```bash
# 1. Yêu cầu nâng vCPU On-Demand Standard lên 16 vCPUs (Account Core)
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 16 \
  --region ap-southeast-1 \
  --profile datablue-prod-core

# 2. Yêu cầu nâng vCPU cho cụm Scenario 3 High-Scale lên 128 vCPUs
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --desired-value 128 \
  --region ap-southeast-1 \
  --profile datablue-prod-core

# 3. Yêu cầu nâng Elastic IP (EIP) lên 10 IP
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --desired-value 10 \
  --region ap-southeast-1 \
  --profile datablue-prod-core
```

#### B. Đối soát Trạng thái Yêu cầu Nâng Quota (Track Quota Increase Request Status):
```bash
# Xem lịch sử và trạng thái duyệt của AWS Support đối với các yêu cầu đã gửi
aws service-quotas list-requested-service-quota-change-history \
  --region ap-southeast-1 \
  --profile datablue-prod-core \
  --query "RequestedQuotas[*].[Id, QuotaName, DesiredValue, Status, Created]" \
  --output table
```

---

## 3. Terraform Remote State Backend & DynamoDB Lock Bootstrap

Execute the automated shell script below to provision S3 State Buckets and DynamoDB Lock Tables across all target accounts:

```bash
#!/usr/bin/env bash
set -euo pipefail

REGION="ap-southeast-1"

# 1. Create S3 Buckets for State Storage with KMS Encryption & Versioning
for BUCKET in "datablue-test-tfstate-${REGION}" "datablue-prod-tfstate-${REGION}" "datablue-prod-ha-tfstate-${REGION}" "datablue-prod-dr-tfstate-${REGION}" "datablue-landing-zone-tfstate"; do
  echo "Creating S3 State Bucket: ${BUCKET}..."
  aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
  aws s3api put-bucket-versioning --bucket "${BUCKET}" --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "${BUCKET}" --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
done

# 2. Create DynamoDB Tables for State Locking
for TABLE in "datablue-test-tflocks" "datablue-prod-tflocks" "datablue-prod-ha-tflocks" "datablue-prod-dr-tflocks" "datablue-landing-zone-tflocks"; do
  echo "Creating DynamoDB Lock Table: ${TABLE}..."
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "${REGION}" || true
done

echo "✅ Remote State Backend Bootstrap Complete!"
```

---

## 4. AWS Service-Linked Roles Initialization

Ensure the required AWS Service-Linked Roles exist in your AWS Account prior to launching EKS, RDS, or ElastiCache:

```bash
# Create Service-Linked Role for EKS
aws iam create-service-linked-role --aws-service-name eks.amazonaws.com || true

# Create Service-Linked Role for RDS
aws iam create-service-linked-role --aws-service-name rds.amazonaws.com || true

# Create Service-Linked Role for ElastiCache
aws iam create-service-linked-role --aws-service-name elasticache.amazonaws.com || true

# Create Service-Linked Role for OpenSearch
aws iam create-service-linked-role --aws-service-name opensearchservice.amazonaws.com || true
```

---

## 5. Pre-Deployment Readiness Verification Checklist

Before running `terraform apply` on any scenario, complete this checklist:

- [ ] Workstation CLI tools installed (`terraform`, `aws`, `kubectl`, `helm`).
- [ ] AWS SSO Session authenticated (`aws sso login`).
- [ ] Service Quotas verified (Graviton vCPU > 64, EIPs > 3).
- [ ] S3 State Buckets and DynamoDB Lock Tables provisioned.
- [ ] AWS Service-Linked Roles initialized.
- [ ] Formal Acceptance Gate Authorization approved by CAB (`GATE-02` for Test, `GATE-07` for Prod).
