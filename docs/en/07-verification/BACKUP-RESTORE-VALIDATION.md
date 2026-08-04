# Backup & Restore Validation Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **Backup & Point-in-Time Recovery (PITR) Validation Specification** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirement [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md) and [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md):
* Backups operate independently from High Availability to protect against data corruption or accidental deletion.
* Monthly restore drills validate point-in-time recovery to isolated Test subnets.
* **No test results are pre-marked as passed**. All backup validation items are currently in `Pending` status.

---

## 2. Backup & Restore Validation Matrix

| Target State Domain | Governing Requirement / ADR | Backup Lifecycle Policy | Target Pass Recovery Criteria | Mandatory Evidence ID | Responsible Owner | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Relational Database (MySQL)**| [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Daily automated snapshots + 30-day PITR continuous transaction log | 100% database record recovery to exact timestamp | `EVD-DB-001` | DBA Lead | `Pending` |
| **2. Document Store (MongoDB)** | [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Daily volume snapshots + oplog continuous archiving (30-day PITR) | Complete oplog replay to target recovery second | `EVD-DB-002` | DBA Lead | `Pending` |
| **3. In-Memory Cache (Redis)** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Daily RDB snapshots exported to encrypted S3 bucket | Redis RDB snapshot restore to new node (< 15m) | `EVD-CACHE-002` | Infrastructure Lead | `Pending` |
| **4. EKS Kubernetes Cluster State**| [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Velero daily backup of CRDs, manifests, and PVC volume snapshots | Full cluster manifest & volume restore to Test EKS | `EVD-BK-001` | SRE Lead | `Pending` |
| **5. Cross-Account Backup Copy** | [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Automated copy to isolated Security AWS Account | Verified immutable backup copy in Security Account | `EVD-BK-002` | Cloud Security Lead | `Pending` |
| **6. Ransomware Protection** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | AWS Backup Vault Lock in Compliance mode | 0 retention policy overrides or premature deletes | `EVD-BK-003` | Cloud Security Lead | `Pending` |

---

## 3. Restore Test Procedures

### Test BAK-01 — MySQL Point-in-Time Recovery (PITR) Drill
* **Procedure**:
  1. Insert timestamped test records into `DataBlue-Prod-Account` MySQL database.
  2. Simulate accidental database table truncation at timestamp `T_drop`.
  3. Initiate AWS RDS PITR restore to target timestamp `T_drop - 1 second` into an isolated Test VPC database subnet.
* **Pass Criteria**: 100% of data records prior to `T_drop` restored successfully; verified zero missing transactions (`EVD-DB-001`).

### Test BAK-02 — Velero Cluster State Recovery Drill
* **Procedure**: Execute `velero restore create --from-backup prod-daily-backup` into an empty Test EKS cluster.
* **Pass Criteria**: 100% of Kubernetes Deployment manifests, ConfigMaps, Secrets, and EBS PersistentVolumeClaims restored to `Ready` state (`EVD-BK-001`).
