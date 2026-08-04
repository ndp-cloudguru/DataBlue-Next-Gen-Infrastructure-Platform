# Open Questions Register: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document tracks prioritized open architectural, operational, and financial questions for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

Questions are focused on high-impact decisions that materially influence AWS architecture design, infrastructure topology, security boundaries, and AWS cloud expenditure.

---

## 2. High-Impact Architecture & Cost Questions

### `OPEN-001`: Microservice Workload Profiling & Resource Sizing
* **Impact Level**: **CRITICAL** (Directly impacts EKS node sizing, EC2 instance families, and total AWS cost).
* **Question**: What are the average and peak CPU, Memory, Storage IOPS, and network throughput specifications for each of the ~40 microservices across the 5–6 business systems?
* **Why It Matters**: Without sizing data, node provisioning relies on provisional assumptions (`ASM-006`), risking over-spending or under-provisioning.
* **Target Decision Stage**: Phase 1 / Phase 2 (Prior to IaC sizing finalization).
* **Action Required**: Customer to run workload profiling tools or supply legacy server metrics.

---

### `OPEN-002`: Stateful Middleware Deployment Model (Managed AWS vs Self-Hosted on EKS)
* **Impact Level**: **CRITICAL** (Impacts operational complexity, backup/DR automation, and AWS monthly spend).
* **Question**: For MySQL, RabbitMQ, MongoDB, Redis, and Nacos, does the organization prefer:
  1. Fully Managed AWS Services (e.g. AWS RDS MySQL, Amazon ElastiCache Redis, Amazon DocumentDB / MongoDB Atlas, Amazon MSK / Self-Hosted RabbitMQ on EC2)?
  2. Self-Hosted Middleware Operators deployed directly inside EKS (e.g. ECK, KubeBlocks, Bitnami Helm Chart Operators with EBS persistent volumes)?
* **Why It Matters**: Managed services reduce operational burden but increase AWS billable costs; EKS operators reduce cloud vendor lock-in but require dedicated SRE maintenance.
* **Target Decision Stage**: Phase 1 (To be evaluated via formal ADR).
* **Action Required**: Architecture Team to present TCO & operational complexity comparison.

---

### `OPEN-003`: Target Regional Availability & Disaster Recovery (DR) SLAs
* **Impact Level**: **HIGH** (Impacts RTO/RPO requirements, cross-region data transfer fees, and multi-region architecture).
* **Question**: What are the specific Recovery Time Objective (RTO) and Recovery Point Objective (RPO) targets for each of the 5–6 business systems during a regional outage?
* **Why It Matters**: High Availability (Multi-AZ within 1 region) protects against node/zone failure. Full Disaster Recovery (Cross-Region failover) requires active-passive or active-active replication, doubling baseline infrastructure costs.
* **Target Decision Stage**: Phase 1 ADR.
* **Action Required**: Business Product Owners to define business continuity tiering.

---

### `OPEN-004`: Network Connectivity & On-Premises / Multi-Cloud Integration
* **Impact Level**: **HIGH** (Impacts AWS VPC CIDR allocation, Transit Gateway setup, AWS Direct Connect / VPN costs).
* **Question**: Do any of the 5–6 business systems require hybrid connectivity to on-premises data centers, external third-party payment gateways, or existing legacy databases via AWS Direct Connect / Site-to-Site VPN?
* **Why It Matters**: Determines VPC network layout, NAT Gateway throughput sizing, transit routing, and hybrid security filtering policies.
* **Target Decision Stage**: Phase 1 Architecture Design.
* **Action Required**: Customer Network Infrastructure Team to provide network integration diagram.

---

### `OPEN-005`: Multi-Account Governance & Security Compliance Framework
* **Impact Level**: **MEDIUM-HIGH** (Impacts AWS Control Tower, IAM Identity Center / SSO, audit logging, compliance scope).
* **Question**: Does the organization enforce specific regulatory compliance frameworks (e.g. PCI-DSS, ISO 27001, SOC2, HIPAA), and is there an existing AWS Organizations / Control Tower landing zone established?
* **Why It Matters**: Dictates security policy boundaries, centralized CloudTrail log aggregation, KMS key rotation rules, and IAM integration.
* **Target Decision Stage**: Phase 0 / Phase 1 Governance Alignment.
* **Action Required**: Customer Security & Compliance Team to confirm audit requirements.

---

### `OPEN-006`: CI/CD Pipeline Automation & Governance Boundaries
* **Impact Level**: **MEDIUM** (Impacts developer workflow, container registry structure, secret management).
* **Question**: How should secrets (database credentials, API keys, certificates) be injected across the GitLab → Jenkins → Ansible → EKS deployment pipeline (e.g. AWS Secrets Manager, HashiCorp Vault, or Sealed Secrets)?
* **Why It Matters**: Prevents hardcoded pipeline secrets and establishes secure GitOps / Ansible execution principles.
* **Target Decision Stage**: Phase 2 Detailed Technical Design.
* **Action Required**: DevOps Team alignment on secret store tooling.
