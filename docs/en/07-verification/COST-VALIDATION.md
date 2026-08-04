# FinOps Cost Governance & Validation Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **FinOps Cost Governance & Sizing Validation Plan** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirements [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), and [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md):
* Actual AWS spend is audited monthly against the Parametric Cost Model ([`COST-MODEL.md`](../05-cost/COST-MODEL.md)) and Scenarios A through E ([`COST-SCENARIOS.md`](../05-cost/COST-SCENARIOS.md)).
* **No test results are pre-marked as passed**. All cost validation items are currently in `Pending` status.

---

## 2. Cost Governance Validation Matrix

| FinOps Governance Domain | Governing Requirement / Policy | Audit Verification Scope | Target Pass Acceptance Criteria | Mandatory Evidence ID | Responsible Owner | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Resource Tag Compliance** | [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | AWS Config Tagging Policy Rule Audit | **100%** of provisioned AWS resources contain valid tags | `EVD-CST-001` | FinOps Lead | `Pending` |
| **2. Spend vs Model Variance** | [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-MODEL.md`](../05-cost/COST-MODEL.md) | Monthly AWS Cost Explorer bill vs Scenario baseline | Monthly AWS spend variance within **±15%** of Cost Model | `EVD-CST-002` | FinOps Lead | `Pending` |
| **3. Non-Prod Auto Scale-Down**| [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | Scheduled scaling down of Test EKS worker nodes | 70% node drop outside business hours (nights/weekends) | `EVD-CST-003` | SRE Lead | `Pending` |
| **4. Spot Instance Utilization** | [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | Test EKS worker node instance pricing type mix | **≥ 70%** EC2 Spot instances in Test environment | `EVD-CST-004` | Infrastructure Lead | `Pending` |
| **5. Savings Plans Coverage** | [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | Compute Savings Plans applied to Prod EKS baseline | **≥ 80%** baseline Production EC2 covered by Savings Plan | `EVD-CST-005` | FinOps Lead | `Pending` |
| **6. Log Archiving Lifecycles** | [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-012`](../03-decisions/ADR-012-observability.md) | S3 Bucket Lifecycle Rules for Fluent Bit logs | Logs transition from S3 Standard to Glacier in 30 days | `EVD-OPS-002` | Operations Lead | `Pending` |
| **7. AWS Budget Alert Triggers**| [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | AWS Budgets & Anomaly Detector alert integration | Automated Slack/Email alerts at 85% budget threshold | `EVD-CST-006` | FinOps Lead | `Pending` |

---

## 3. Cost Validation Audit Protocol

### Test CST-01 — AWS Resource Tag Compliance Audit
* **Procedure**: Run AWS Config rule `required-tags` across all AWS Accounts (`DataBlue-Test`, `DataBlue-Prod`, `Shared-Services`, `Security`).
* **Required Tag Keys**: `Environment`, `BusinessSystem`, `CostCenter`, `Owner`.
* **Pass Criteria**: `0` non-compliant untagged AWS resources (`EVD-CST-001`).

### Test CST-02 — Monthly Spend Model Variance Audit
* **Procedure**: Extract AWS Cost Explorer monthly invoice and compare against Scenario C Production Baseline (~$3,800/mo).
* **Pass Criteria**: Total AWS spend remains within ±15% threshold; evidence attached as `EVD-CST-002`.
