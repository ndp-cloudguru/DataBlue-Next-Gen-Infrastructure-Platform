# ADR-006 — MySQL Deployment Strategy

## Metadata
* **Status**: `Deferred`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Data Architect, Cloud Infrastructure Lead
* **Reviewers**: Enterprise Architecture Board, FinOps Team
* **Related Requirements**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-UNC-001` (Missing DB workload profiles), `RSK-OPS-001` (Self-hosted DB operational burden), `RSK-CST-001` (Managed DB cost growth)
* **Related Assumptions**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 3, Section 6
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `FUN-005` specifies high-availability MySQL relational database services for application data persistence. We must determine the deployment topology for MySQL (Self-Hosted on EKS vs. Amazon RDS for MySQL vs. Amazon Aurora MySQL). Workload metrics (DB size, IOPS, connection concurrency, read/write ratio) are currently unavailable (`OPEN-001`).

---

## Decision Drivers
1. **High Availability & Automated Failover**: Multi-AZ synchronous/asynchronous replication with zero data loss target (`NFR-001`).
2. **Operational & Backup Burden**: Automated patching, point-in-time recovery (PITR), and storage auto-scaling (`NFR-003`).
3. **Total Cost of Ownership (TCO)**: Evaluating software licensing, cloud infrastructure pricing, and ongoing DBA operational labor (`CST-001`).
4. **Data Vendor Lock-in & Portability**: Freedom to migrate database state across clouds or on-premises.

---

## Constraints
* Must support standard MySQL 8.0+ wire protocol.

---

## Options Considered

### Option 1: Self-Hosted MySQL Operator on EKS (e.g. Bitnami / KubeBlocks Operator)
* **Description**: Deploying MySQL master-replica clusters inside EKS using Kubernetes Operators backed by EBS persistent volumes (`gp3`).
* **Advantages**: Eliminates AWS managed database premium fees; full administrative access to MySQL configuration variables; complete cloud portability.
* **Disadvantages**: High operational complexity; team must manage stateful volume failover, manual replication repair, EBS snapshot lifecycle, and DBA patching.
* **Security Implications**: Moderate. Security hardening and KMS volume encryption managed by team.
* **Availability Implications**: Moderate. Subject to Kubernetes pod reschedule delays and EBS volume re-attach latencies (~2-5 minutes during AZ outage).
* **Scalability Implications**: Manual read-replica pod scaling and EBS volume expansion.
* **Operational Implications**: Heavy ongoing DBA and SRE labor burden (`RSK-OPS-001`).
* **Cost Implications**: Lower AWS infrastructure cost, but high ongoing labor maintenance cost.
* **Vendor Lock-in**: Very Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Dedicated DBA / SRE team with Kubernetes StatefulSet expertise.
* **Risks**: `RSK-OPS-001` (Database volume corruption or replication failure during node crashes).

### Option 2: Amazon RDS for MySQL (Multi-AZ)
* **Description**: Provisioning fully managed Amazon RDS MySQL instances deployed across 2-3 Availability Zones with automated failover.
* **Advantages**: Offloads 95% of DBA operational tasks; automated Multi-AZ failover (< 60 seconds); automated daily backups and PITR; managed security patching.
* **Disadvantages**: Higher AWS hourly instance pricing compared to raw EC2/EKS compute.
* **Security Implications**: Excellent. Native AWS KMS encryption, IAM database authentication, VPC subnet isolation.
* **Availability Implications**: Strong. 99.95% uptime SLA backed by AWS.
* **Scalability Implications**: Easy vertical instance scaling and read-replica endpoint addition.
* **Operational Implications**: Minimal operational maintenance required from DevOps team.
* **Cost Implications**: Moderate-High AWS monthly spend.
* **Vendor Lock-in**: Low-Moderate (Standard MySQL engine compatibility).
* **Migration Complexity**: Low (Standard `mysqldump` / AWS DMS).
* **Reversibility**: Reversible with migration.
* **Preconditions**: Isolated Database VPC Subnets (`SEC-002`).
* **Risks**: `RSK-CST-001` (Uncontrolled managed database cost growth if unmonitored).

### Option 3: Amazon Aurora MySQL-Compatible
* **Description**: AWS proprietary cloud-native relational database engine offering distributed storage replicated 6 ways across 3 AZs.
* **Advantages**: High performance (up to 5x standard MySQL throughput); auto-scaling storage up to 128TB; near-instantaneous crash recovery (< 30 seconds).
* **Disadvantages**: Substantially higher baseline cost; proprietary AWS storage engine layer.
* **Security Implications**: Excellent.
* **Availability Implications**: Excellent (99.99% SLA).
* **Scalability Implications**: Excellent (Fast read replicas and storage auto-expansion).
* **Operational Implications**: Minimal management overhead.
* **Cost Implications**: Highest cost option (20-40% premium over standard RDS).
* **Vendor Lock-in**: High (Aurora storage architecture lock-in).
* **Migration Complexity**: Moderate.
* **Reversibility**: Reversible with migration.
* **Preconditions**: Requirement for high write throughput exceeding standard RDS capabilities.
* **Risks**: Cloud vendor lock-in and high monthly spend.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: MySQL on EKS Operator | Option 2: Amazon RDS MySQL | Option 3: Amazon Aurora MySQL |
| :--- | :--- | :--- | :--- |
| **Availability & SLA (`NFR-001`)** | Moderate | **Strong (99.95%)** | **Strong (99.99%)** |
| **Operational Labor Overhead** | Heavy | **Minimal** | **Minimal** |
| **Performance Ceiling** | Moderate | Moderate-High | **High** |
| **Cost Efficiency (`CST-001`)** | High Infra / High Labor | **Balanced** | Low (High AWS Premium) |
| **Vendor Lock-in** | **Very Low** | Moderate | High |

---

## Proposed Decision
**Decision Deferred**.

---

## Rationale
A final architectural selection between Amazon RDS for MySQL (Option 2) and Self-Hosted MySQL Operator on EKS (Option 1) **cannot be defensibly made without empirical database workload profiling data** (`OPEN-001`). 

Selecting Option 2 without sizing risks budget overruns; selecting Option 1 without DBA team metrics risks operational failure.

---

## Validation Evidence Required Before Acceptance
1. Microservice MySQL database data size, transaction RPS, read/write ratio, and connection pool requirements (`OPEN-001`).
2. DBA operational capability and incident response SLA sign-off.
3. FinOps monthly budget allocation review.

## Acceptance Conditions
* Submission of verified customer database workload metrics and formal Architecture Board review.

## Revisit Triggers
* Completion of Phase 1 workload profiling.

## Implementation Implications
* Architecture design maintains abstract database subnet isolation in IaC until Phase 1 decision sign-off.
