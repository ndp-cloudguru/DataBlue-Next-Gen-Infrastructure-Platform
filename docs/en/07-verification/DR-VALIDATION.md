# Disaster Recovery Validation Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **Disaster Recovery (DR) Regional Failover Validation Specification** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirement [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md) and [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md):
* DR drills simulate total catastrophic outage of the primary AWS Region (e.g. `us-east-1`).
* **No test results are pre-marked as passed**. All DR validation items are currently in `Deferred` status pending business RTO/RPO SLA sign-off (`OPEN-003`).

---

## 2. Disaster Recovery Validation Matrix

| DR Component Scope | Governing Requirement / ADR | Target Recovery SLA | Target Pass Verification Criteria | Mandatory Evidence ID | Responsible Owner | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Target Recovery Time (RTO)** | [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **RTO < 4 Hours** | Full secondary region platform online & serving traffic in < 4h | `EVD-DR-001` | Lead Cloud Architect | `Deferred` (Pending SLA) |
| **2. Target Recovery Point (RPO)** | [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **RPO < 15 Minutes** | Cross-region data loss window verified < 15 minutes | `EVD-DR-001` | DBA Lead / SRE Lead | `Deferred` (Pending SLA) |
| **3. Cloudflare Global Traffic Manager (GTM) / DNS Failover** | [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **DNS Failover < 5 Mins** | Cloudflare DNS/GTM health checks trigger CNAME switch to secondary ALB | `EVD-DR-002` | Network Lead | `Deferred` (Pending SLA) |
| **4. Secondary EKS Cluster Readiness**| [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **Pilot Light / Standby** | EKS cluster control plane active in secondary AWS region | `EVD-DR-003` | Infrastructure Lead | `Deferred` (Pending SLA) |
| **5. Cross-Region Database Copy** | [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **Cross-Region Snapshot** | Multi-region read-replica / snapshot replication active | `EVD-DR-004` | DBA Lead | `Deferred` (Pending SLA) |

---

## 3. Regional Disaster Recovery Failover Test Protocol

### Test DR-01 — Regional Outage & Failover Simulation
* **Procedure**:
  1. Trigger simulated total outage of primary AWS region (`us-east-1`) in Cloudflare DNS / GTM.
  2. Promote cross-region database read-replica in secondary region (`us-west-2`) to Primary.
  3. Scale up secondary EKS Pilot Light worker node groups via Terraform / Karpenter.
  4. Sync microservice deployments using ArgoCD GitOps engine in secondary region.
* **Pass Criteria**:
  1. Secondary region platform reaches 100% operational status within < 4 hours (RTO).
  2. Data loss gap between primary and secondary database tiers verified < 15 minutes (RPO).
  3. Evidence log attached as `EVD-DR-001`.
