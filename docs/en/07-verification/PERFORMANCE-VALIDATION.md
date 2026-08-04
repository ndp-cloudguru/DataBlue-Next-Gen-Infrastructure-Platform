# Performance & Scaling Validation Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **Performance & Scaling Validation Specification** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirements [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) and [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md):
* Synthetic load tests and node autoscaling benchmarks are executed against the Technical Pilot application (`WP-014`).
* **No test results are pre-marked as passed**. All performance validation items are currently in `Pending` status.

---

## 2. Performance & Scaling Validation Matrix

| Performance Category | Governing Requirement / ADR | Validation Audit Scope | Target Acceptance Pass Criteria | Mandatory Evidence ID | Responsible Owner | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Ingress Latency (P95)** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md) | ALB Ingress API response time under baseline load | P95 Latency < 200ms at ALB entry boundary | `EVD-PRF-001` | Performance Lead | `Pending` |
| **2. Ingress Latency (P99)** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md) | ALB Ingress API response time under baseline load | P99 Latency < 500ms at ALB entry boundary | `EVD-PRF-001` | Performance Lead | `Pending` |
| **3. Burst Load Capacity** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | Distributed k6 load burst (200% peak throughput) | Zero HTTP 500 errors under 200% load burst | `EVD-PRF-001` | Performance Lead | `Pending` |
| **4. Pod Autoscaling (HPA)** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | HPA pod replica scaling upon 70% CPU trigger | Pod replicas scale up within < 30 seconds | `EVD-SCL-001` | SRE Lead | `Pending` |
| **5. Node Autoscaling** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | Karpenter JIT EC2 node provisioning | New node provisioned & ready in < 60s | `EVD-SCL-001` | SRE Lead | `Pending` |
| **6. Database Read Latency** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | MySQL Read-Replica endpoint query performance | P95 DB query latency < 10ms | `EVD-DB-003` | DBA Lead | `Pending` |
| **7. Redis Cache Latency** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | ElastiCache Redis cluster read/write response | Redis command response latency < 2ms | `EVD-CACHE-001` | Infrastructure Lead | `Pending` |

---

## 3. Scaling Benchmark Test Execution Protocol

### Test PRF-01 — Karpenter Node Provisioning Latency Benchmark
* **Procedure**: Inject 50 unschedulable pod resource requests into EKS Test Cluster simultaneously.
* **Metric**: Time elapsed between `PodScheduled: False` state and `NodeReady: True` state.
* **Pass Criteria**: Karpenter provisions requested EC2 instance node and reaches `Ready` state in < 60 seconds (`EVD-SCL-001`).

### Test PRF-02 — 10,000 Concurrent User Load Test
* **Procedure**: Execute 15-minute distributed k6 load test simulating 10,000 concurrent virtual users targeting microservice API endpoints.
* **Pass Criteria**: Error rate < 0.01%, ALB P95 latency < 200ms (`EVD-PRF-001`).
