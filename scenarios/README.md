# DataBlue Next-Gen Infrastructure Platform — Terraform Scenarios Directory

**Project Identifier**: `datablue-nextgen-infra-platform`  
**Governance Standard**: Architecture-First Governance Standard (`ADR-015`)

---

## 📌 Directory Overview

This directory contains production-ready **Terraform Infrastructure as Code (IaC)** configurations and 8 reusable core modules for the 5 enterprise deployment scenarios defined in [`COST-SCENARIOS.md`](../docs/en/05-cost/COST-SCENARIOS.md) and [`PROPOSAL.md`](../docs/en/PROPOSAL.md):

```text
scenarios/
├── README.md                                    # Scenarios documentation and execution guide
├── modules/                                     # Reusable Production Core Terraform Modules
│   ├── vpc/                                     # 3-Tier VPC Networking (Public, Private App, Isolated DB)
│   ├── kms/                                     # KMS Customer Managed Key (CMK) for At-Rest Encryption
│   ├── eks/                                     # Amazon EKS v1.30+ Control Plane, IRSA OIDC & Karpenter Roles
│   ├── rds_mysql/                               # Amazon RDS MySQL Multi-AZ with 30-Day PITR Backups
│   ├── elasticache_redis/                       # Amazon ElastiCache Redis Cluster with TLS & Auth Token
│   ├── amazon_mq_rabbitmq/                      # Amazon MQ RabbitMQ 3-Node Quorum Broker with AMQP TLS
│   ├── documentdb/                              # Amazon DocumentDB 3-Node Cluster (MongoDB Compatible)
│   └── opensearch/                              # Amazon OpenSearch Service Multi-AZ Cluster
├── scenario-1-test-baseline/                    # Scenario 1: Standard Non-Prod Test Baseline ($1.6k-$2.4k/mo)
├── scenario-2-prod-baseline/                    # Scenario 2: Production Baseline ($4.2k-$6.1k/mo)
├── scenario-3-prod-high-scale-ha/               # Scenario 3: Production High-Scale HA ($7.2k-$10.5k/mo)
├── scenario-4-prod-cross-region-dr/             # Scenario 4: Production Cross-Region DR ($10k-$14.8k/mo)
└── scenario-5-enterprise-multi-account/         # Scenario 5: Enterprise Multi-Account Isolation ($12k-$18.5k/mo)
```

---

## 🏛️ Scenario Infrastructure & Operations Matrix

All operational runbooks are consolidated under the central [**`operations/`**](operations/) directory:

| Scenario Directory | Operations Runbook | Target Monthly Budget | Reused Core Modules & Key Components |
| :--- | :--- | :--- | :--- |
| 📁 [**`scenario-1-test-baseline/`**](scenario-1-test-baseline/) | 📖 [**`SCENARIO-1-OPERATIONS.md`**](operations/SCENARIO-1-OPERATIONS.md) | **$1,600 – $2,400 / mo** | Reuses `kms`, `vpc` (2-AZ), `eks` (Spot nodes), `rds_mysql` (`db.m6g.large`), `elasticache_redis`, `amazon_mq_rabbitmq`, `documentdb`, `opensearch`. |
| 📁 [**`scenario-2-prod-baseline/`**](scenario-2-prod-baseline/) | 📖 [**`SCENARIO-2-OPERATIONS.md`**](operations/SCENARIO-2-OPERATIONS.md) | **$4,200 – $6,100 / mo** | Reuses `kms`, `vpc` (3-AZ), `eks` (Savings Plans nodes), `rds_mysql` (`db.m6g.xlarge`), `elasticache_redis`, `amazon_mq_rabbitmq`, `documentdb`, `opensearch`. |
| 📁 [**`scenario-3-prod-high-scale-ha/`**](scenario-3-prod-high-scale-ha/) | 📖 [**`SCENARIO-3-OPERATIONS.md`**](operations/SCENARIO-3-OPERATIONS.md) | **$7,200 – $10,500 / mo** | Reuses `kms`, `vpc`, `eks` (~28 nodes), `elasticache_redis` (6-Node Sharded), `amazon_mq_rabbitmq`, `documentdb`, `opensearch` (4-Node) + Aurora MySQL 3 Replicas. |
| 📁 [**`scenario-4-prod-cross-region-dr/`**](scenario-4-prod-cross-region-dr/) | 📖 [**`SCENARIO-4-OPERATIONS.md`**](operations/SCENARIO-4-OPERATIONS.md) | **$10,000 – $14,800 / mo** | Dual AWS Providers: Primary `us-east-1` Active Prod + Secondary `us-west-2` Pilot Light Standby (`kms`, `vpc`, `eks`, `rds_mysql`, S3 CRR). |
| 📁 [**`scenario-5-enterprise-multi-account/`**](scenario-5-enterprise-multi-account/) | 📖 [**`SCENARIO-5-OPERATIONS.md`**](operations/SCENARIO-5-OPERATIONS.md) | **$12,000 – $18,500 / mo** | 5-Account Landing Zone (`Prod Core`, `Prod Entry A`, `Prod Entry B`, `Dev/Test Isolated`, `Shared Services`), Central TGW Hub (`kms`, `vpc`, `eks`, `rds_mysql`). |

---

## 🛠️ Terraform Version & Provider Constraints

All Terraform modules enforce standard provider constraints (`ADR-015`):

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}
```

---

## 🚀 Execution Workflow

To evaluate or plan any scenario infrastructure:

```bash
# 1. Navigate to target scenario directory
cd scenarios/scenario-1-test-baseline

# 2. Initialize Terraform modules and backend
terraform init

# 3. Create execution plan for audit
terraform plan -out=tfplan

# 4. Apply configuration (upon GATE-07 CAB authorization)
terraform apply tfplan
```
