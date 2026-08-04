# ADR-013 — Backup Strategy

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Infrastructure Architect, Database Administrator
* **Reviewers**: Enterprise Architecture Board, Security Team
* **Related Requirements**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-DAT-002` (Untested backup restoration failures), `RSK-SEC-003` (Ransomware backup destruction)
* **Related Assumptions**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 12
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `NFR-003` mandates recoverability mechanisms to protect application state against accidental deletion, data corruption, or ransomware attack. High Availability (Multi-AZ redundancy) protects against hardware failure, but **does not protect against data corruption or accidental deletions**. We must establish a point-in-time backup strategy that is explicitly decoupled from HA and Disaster Recovery.

---

## Decision Drivers
1. **Point-in-Time Recovery (PITR)**: Ability to restore relational and document databases to any specific second within a 30-day window (`NFR-003`).
2. **Kubernetes Cluster State Capture**: Backing up custom resource definitions (CRDs), secrets, configmaps, and persistent volumes (`OPS-002`).
3. **Cross-Account Ransomware Protection**: Replicating immutable backup snapshots into an isolated Security AWS Account (`SEC-002`).

---

## Constraints
* Backups must run automatically without causing database performance degradation.

---

## Options Considered

### Option 1: Service-Native Backups Only (Individual DB Dump Scripts)
* **Description**: Running custom cron scripts (`mysqldump`, `mongodump`) executing inside pods or EC2 nodes, writing dump files to local disk or S3.
* **Advantages**: Simple script setup.
* **Disadvantages**: Heavy CPU/memory performance hit during dump execution; lacks point-in-time recovery precision; highly vulnerable to script failures and missing Kubernetes state.
* **Security Implications**: Weak. Unencrypted dump files on local disks.
* **Availability Implications**: Weak. High risk of table locks during dump.
* **Scalability Implications**: Poor. Fails for multi-gigabyte databases.
* **Operational Implications**: Heavy script maintenance burden.
* **Cost Implications**: Low AWS service fees.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: High.
* **Reversibility**: Difficult.
* **Preconditions**: None.
* **Risks**: `RSK-DAT-002` (Inconsistent database snapshots and corrupted backups).

### Option 2: Pure AWS Backup Service
* **Description**: Utilizing centralized AWS Backup policies to snapshot AWS RDS, EBS volumes, and S3 buckets.
* **Advantages**: Single centralized AWS backup dashboard; automated AWS Backup Vault Lock (ransomware protection); cross-account copy support.
* **Disadvantages**: Does not natively capture Kubernetes application manifests, CRDs, or in-cluster statefulset volume claims.
* **Security Implications**: Excellent. KMS encryption, AWS Backup Vault Lock.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: Minimal management overhead.
* **Cost Implications**: Standard AWS storage snapshot pricing.
* **Vendor Lock-in**: Moderate (AWS Backup format).
* **Migration Complexity**: Low.
* **Reversibility**: Reversible.
* **Preconditions**: AWS Backup Vault setup.
* **Risks**: Missing Kubernetes operational state during full cluster rebuilds.

### Option 3: Hybrid Backup Model (Service-Native DB PITR + Velero EKS State Backups)
* **Description**: A comprehensive two-part backup architecture:
  1. **Database Tier**: Automated daily managed snapshots with continuous transaction logging enabling 30-day Point-in-Time Recovery (PITR) for MySQL, MongoDB, and Redis (`NFR-003`).
  2. **Kubernetes Tier**: Velero Backup Operator installed in EKS, scheduling daily backups of cluster CRDs, namespaces, secrets, and EBS volume snapshots directly to encrypted S3 buckets (`OPS-002`).
  3. **Cross-Account Ransomware Isolation**: Automated replication of S3 backup snapshots to the isolated Security AWS Account (`SEC-002`).
* **Advantages**: Covers 100% of database state and Kubernetes operational manifests; zero database table locking; immutable ransomware protection; rapid full-cluster restoration.
* **Disadvantages**: Requires maintaining Velero operator CRDs and S3 bucket IAM policies.
* **Security Implications**: Strongest. KMS encryption at rest + cross-account immutable S3 bucket protection (`SEC-002`).
* **Availability Implications**: High. Automated background backups.
* **Scalability Implications**: High.
* **Operational Implications**: Low operational maintenance.
* **Cost Implications**: Highly cost-effective (S3 lifecycle rules optimize snapshot storage costs).
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Velero S3 bucket and IAM IRSA setup.
* **Risks**: `RSK-DAT-002` (Failure to perform periodic backup restoration dry-runs).

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Dump Scripts | Option 2: Pure AWS Backup | Option 3: Hybrid (Native DB + Velero) |
| :--- | :--- | :--- | :--- |
| **Point-in-Time Recovery (PITR)** | Weak | Strong | **Strong (Second-level precision)** |
| **K8s State Capture (`OPS-002`)** | Non-Existent | Weak | **Strong (Velero CRDs)** |
| **Ransomware Isolation (`SEC-002`)** | Weak | Strong | **Strong (Cross-Account S3 Copy)** |
| **Operational Reliability** | Low | High | **High** |
| **Reversibility** | Difficult | Reversible | **Easily Reversible** |

---

## Proposed Decision
**Option 3: Hybrid Backup Model** (Service-Native Database Snapshots with PITR + Velero EKS State Backups to S3).

---

## Rationale
Option 3 provides absolute recoverability for both database transaction state and Kubernetes configuration manifests (`NFR-003`), while enforcing cross-account immutable S3 backup copy isolation to guarantee recovery even if an environment account is compromised.

---

## Consequences
* **Positive**: Complete 30-day PITR database recovery; automated Kubernetes cluster state restoration via Velero; ransomware-proof cross-account backup copies.
* **Negative**: Requires configuring Velero S3 bucket replication policies.
* **New Operational Responsibilities**: Executing quarterly automated backup restoration dry-runs (`RSK-DAT-002`).
* **New Risks**: `RSK-DAT-002` (Unvalidated backup restoration procedures).
* **Cost Consequences**: Nominal S3 snapshot storage fees.

---

## Validation Evidence
* Velero cluster restore dry-run and database point-in-time snapshot recovery verification.

## Acceptance Conditions
* Infrastructure Lead and Security Team sign-off.

## Revisit Triggers
* Regulatory mandate requiring multi-year offline tape backup compliance.

## Implementation Implications
* Velero Helm chart and AWS Backup lifecycle policies provisioned in Phase 3.
