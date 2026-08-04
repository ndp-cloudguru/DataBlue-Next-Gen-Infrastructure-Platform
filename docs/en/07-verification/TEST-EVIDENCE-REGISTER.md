# Test Evidence Register: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **Master Test Evidence Register** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with Stage 5 rules:
* **No gate approval (`GATE-01` to `GATE-10`) is granted without verified evidence attached to this register**.
* Every evidence item requires a physical artifact path, execution timestamp, SHA-256 hash, responsible engineer, and verification status.

---

## 2. Master Test Evidence Catalog

| Evidence ID | Target Acceptance Gate | Evidence Artifact Description | Required Artifact Format / File Type | Responsible Engineer | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`EVD-EVD-001`** | [`GATE-01`](../04-planning/ACCEPTANCE-GATES.md) | Workload Evidence Profiling Report (CPU/RAM/IOPS) | `profiling_report.pdf` | Lead Cloud Architect | `Pending` |
| **`EVD-ENV-001`** | [`GATE-04`](../04-planning/ACCEPTANCE-GATES.md) | AWS Landing Zone Account & VPC Isolation Audit | `landing_zone_audit.json` | Cloud Security Lead | `Pending` |
| **`EVD-K8S-001`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | Sonobuoy EKS Kubernetes Conformance Test Output | `sonobuoy_results.tar.gz` | Infrastructure Architect | `Pending` |
| **`EVD-ING-001`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | SSL Labs Grade A Ingress TLS Certificate Scan | `ssl_labs_scan.pdf` | DevOps Engineer | `Pending` |
| **`EVD-SEC-001`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | Trivy Container Vulnerability Scan Report (0 Critical) | `trivy_scan_report.json` | Cloud Security Lead | `Pending` |
| **`EVD-SEC-002`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | IAM Access Analyzer Least-Privilege Audit (0 `*`) | `iam_policy_audit.json` | Cloud Security Lead | `Pending` |
| **`EVD-SCL-001`** | [`GATE-06`](../04-planning/ACCEPTANCE-GATES.md) | Karpenter Node Autoscaling Benchmark (< 60s) | `karpenter_scale_metrics.csv` | SRE Lead | `Pending` |
| **`EVD-PRF-001`** | [`GATE-06`](../04-planning/ACCEPTANCE-GATES.md) | Technical Pilot Load Testing Report (Locust/k6) | `k6_benchmark_report.html` | Performance Lead | `Pending` |
| **`EVD-CAB-001`** | [`GATE-07`](../04-planning/ACCEPTANCE-GATES.md) | Change Advisory Board (CAB) Signed Authorization Ticket | `cab_release_ticket.pdf` | Project Sponsor | `Pending` |
| **`EVD-DB-001`** | [`GATE-08`](../04-planning/ACCEPTANCE-GATES.md) | RDS MySQL 30-Day PITR Snapshot Restore Verification | `rds_pitr_restore_log.txt` | DBA Lead | `Pending` |
| **`EVD-HA-001`** | [`GATE-08`](../04-planning/ACCEPTANCE-GATES.md) | Chaos Mesh AZ Outage & Node Termination Drill Log | `chaos_failover_log.txt` | SRE Lead | `Pending` |
| **`EVD-DR-001`** | [`GATE-08`](../04-planning/ACCEPTANCE-GATES.md) | Regional Disaster Recovery Drill RTO/RPO SLA Test Log | `dr_failover_drill.log` | Lead Cloud Architect | `Pending` |
| **`EVD-WAV-001`** | [`GATE-09`](../04-planning/ACCEPTANCE-GATES.md) | Application Onboarding Wave Sign-Off Certificates | `wave_1_5_signoff.pdf` | Migration Lead | `Pending` |
| **`EVD-CST-001`** | [`GATE-10`](../04-planning/ACCEPTANCE-GATES.md) | FinOps Resource Tagging Compliance Report (100%) | `aws_cost_tag_audit.csv` | FinOps Lead | `Pending` |
| **`EVD-OPS-001`** | [`GATE-10`](../04-planning/ACCEPTANCE-GATES.md) | Signed Operational Support Handover Certificate | `handover_certificate.pdf` | Operations Lead | `Pending` |

---

## 3. Evidence Storage & Integrity Governance

1. **Storage Location**: All raw test evidence files must be uploaded to the dedicated encrypted S3 Evidence Vault (`s3://databue-test-evidence-vault/`) in the Security Account.
2. **Immutability Policy**: Object Lock enabled on evidence bucket to prevent deletion or alteration of validation evidence.
3. **Traceability Binding**: Evidence IDs (`EVD-xxx`) must be cross-referenced inside [`REQUIREMENT-TRACEABILITY-MATRIX.md`](REQUIREMENT-TRACEABILITY-MATRIX.md).
