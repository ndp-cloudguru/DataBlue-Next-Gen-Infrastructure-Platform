# Cost Assumptions: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies all financial and technical assumptions used to build the **Parametric Cost Model** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirement `BUS-004` and governance rules:
* Cost estimates are **scenario-based (Scenarios A through E)**, not guaranteed single bills.
* All pricing uses standard AWS public region pricing baseline (`us-east-1` / `ap-southeast-1` rates).
* Unconfirmed sizing parameters are governed by provisional service sizing classes (XS, S, M, L, XL).

---

## 2. Core Financial & Technical Assumptions

### 1. Compute & EKS Control Plane
* **EKS Control Plane**: Fixed $0.10 per cluster per hour ($73.00 per month) per environment (`ADR-003`).
* **Worker Instance Pricing Model**:
  * Production: 100% On-Demand pricing baseline; 3-Year Compute Savings Plans yield ~30-40% discount.
  * Test: 70% EC2 Spot instances (~70% discount over On-Demand) + 30% On-Demand (`ADR-005`).
* **Provisional Microservice Resource Density**: ~40 microservices distributed across sizing classes:
  * Class XS (Micro): 0.1 vCPU, 0.25 GB RAM (10 services)
  * Class S (Small): 0.25 vCPU, 0.5 GB RAM (15 services)
  * Class M (Medium): 0.5 vCPU, 1.0 GB RAM (10 services)
  * Class L (Large): 1.0 vCPU, 2.0 GB RAM (5 services)

### 2. Network & Data Transfer
* **NAT Gateways**: $0.045 per NAT Gateway per hour ($32.85/month per AZ) + $0.045 per GB data processed.
* **Cross-AZ Data Transfer**: $0.01 per GB intra-VPC inter-AZ traffic. (Optimized via Kubernetes topology-aware routing).
* **Internet Egress**: $0.09 per GB out to public internet for first 10 TB/month.

### 3. Database & Stateful Middleware Tiers
* **Relational MySQL (`FUN-005`)**: Managed Amazon RDS MySQL `db.m6g.xlarge` Multi-AZ ($0.76/hr) or Self-Hosted on EKS compute.
* **In-Memory Redis (`FUN-008`)**: Managed Amazon ElastiCache `cache.m6g.large` Multi-AZ ($0.136/hr) or Self-Hosted on EKS compute.
* **Message Broker RabbitMQ (`FUN-006`)**: Amazon MQ `mq.m6g.large` Multi-AZ ($0.576/hr) or Self-Hosted Operator on EKS.
* **Document Database MongoDB (`FUN-007`)**: Amazon DocumentDB `db.t4g.medium` / `db.r6g.xlarge` or MongoDB Atlas SaaS or Self-Hosted Operator on EKS.

### 4. Storage & Backup Lifecycles
* **EBS Storage (`gp3`)**: $0.08 per GB-month + $0.005 per provisioned IOPS above 3,000 baseline.
* **S3 Standard Storage**: $0.023 per GB-month for active backup snapshots and log exports.
* **S3 Glacier Flexible Retrieval**: $0.004 per GB-month for long-term log archives (after 30 days).
* **AWS Backup Snapshots**: $0.05 per GB-month for RDS/EBS backup storage (`ADR-013`).

### 5. Observability & Logging Ingestion
* **Amazon OpenSearch**: 2-node `r6g.large.search` cluster ($0.163/hr) for 7-day hot log search (`ADR-012`).
* **CloudWatch Ingestion**: $0.50 per GB log data ingested; optimized by filtering debug logs at Fluent Bit daemonset (`RSK-CST-002`).

### 6. Support & Operational Overhead
* **AWS Enterprise Support**: 10% of monthly AWS spend for Production accounts ($15,000 minimum threshold for full Enterprise).
