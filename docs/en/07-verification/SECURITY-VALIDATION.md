# Security Validation Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **Security Validation Specification & Audit Plan** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirements [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), and [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md):
* Security controls are audited across 6 security layers before entering Production (`GATE-07`).
* **No test results are pre-marked as passed**. All security validation items are currently in `Pending` status.

---

## 2. 6-Layer Security Validation Matrix

| Security Layer | Governing Requirement / ADR | Validation Audit Scope | Target Acceptance Pass Criteria | Mandatory Evidence ID | Responsible Owner | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Identity & IAM Scoping** | [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md) | AWS IAM IRSA pod role scoping & IAM Access Analyzer scan | Zero wildcard (`*`) IAM permissions in pod roles | `EVD-SEC-002` | Cloud Security Lead | `Pending` |
| **2. Container Vulnerabilities** | [`FUN-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | Jenkins Trivy CVE scan on container images | Zero `CRITICAL` vulnerabilities in container images | `EVD-SEC-001` | DevOps Lead | `Pending` |
| **3. Network Perimeter Isolation**| [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md) | VPC subnets, Security Groups & NetworkPolicies | Zero direct internet route to isolated DB subnets | `EVD-ENV-001` | Network Architect | `Pending` |
| **4. Secrets Management** | [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md) | AWS Secrets Manager + External Secrets Operator (ESO) | Zero static plain-text secrets checked into Git | `EVD-SEC-005` | Security Engineer | `Pending` |
| **5. Data Encryption at Rest** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md) | AWS KMS Customer-Managed Key (CMK) configuration | 100% encrypted EBS volumes, RDS DBs, & S3 | `EVD-SEC-004` | Cloud Security Lead | `Pending` |
| **6. Data Encryption in Transit** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md) | TLS 1.3 encryption on Ingress ALB & mTLS pod routing | SSL Labs Grade A rating on public endpoints | `EVD-ING-001` | DevOps Engineer | `Pending` |

---

## 3. Security Validation Test Procedures

### Test SEC-01 — Least-Privilege IAM IRSA Audit
* **Procedure**: Execute automated IAM Access Analyzer against all IRSA role ARNs attached to EKS service accounts.
* **Pass Criteria**: `0` policies containing `Action: "*"` or `Resource: "*"`.

### Test SEC-02 — Isolated Database Subnet Ingress Audit
* **Procedure**: Execute synthetic network probe from Test pod targeting Database Subnets on unauthorized ports.
* **Pass Criteria**: 100% of unauthorized connection attempts dropped by AWS Security Groups.

### Test SEC-03 — Container Image Vulnerability Scan
* **Procedure**: Run Trivy vulnerability scan during Jenkins container build pipeline (`FUN-003`).
* **Pass Criteria**: Jenkins build succeeds if and only if zero `CRITICAL` CVEs are found.
