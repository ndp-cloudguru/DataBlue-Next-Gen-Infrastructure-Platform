# ADR Register: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document serves as the master registry for all **Architecture Decision Records (ADRs)** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with Stage 3 rules:
* All ADRs are currently in **`Proposed`** or **`Deferred`** status.
* No decision is marked `Accepted` without explicit human sign-off.

---

## 2. ADR Master Registry

| ADR ID | Title | Status | Primary Requirements | Primary Risks | Decision Dependency | Required Validation Evidence | Target Review Stage | Last Updated |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| [`ADR-001`](ADR-001-aws-account-strategy.md) | AWS Account Strategy | `Proposed` | `BUS-003`, `SEC-002` | `RSK-SEC-003` | None | AWS Landing Zone blueprint review | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-002`](ADR-002-environment-isolation.md) | Environment Isolation Model | `Proposed` | `BUS-003`, `SEC-002`, `NFR-001` | `RSK-SEC-003` | `ADR-001` | EKS multi-account security audit | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-003`](ADR-003-kubernetes-platform.md) | Kubernetes Platform Engine | `Proposed` | `BUS-001`, `FUN-001`, `OPS-001` | `RSK-OPS-001` | `ADR-001`, `ADR-002` | EKS control plane SLA sign-off | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-004`](ADR-004-cicd-operating-model.md) | CI/CD Operating Model | `Proposed` | `BUS-002`, `FUN-002`–`FUN-004` | `RSK-SEC-001`, `RSK-ARC-001` | `ADR-001`, `ADR-011` | Jenkins-Ansible pipeline interface dry-run | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-005`](ADR-005-node-autoscaling.md) | Node Autoscaling Engine | `Proposed` | `NFR-002`, `CST-001` | `RSK-UNC-001`, `RSK-SCL-001` | `ADR-003` | Karpenter provisioning latency benchmark | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-006`](ADR-006-mysql-deployment.md) | MySQL Deployment Strategy | `Deferred` | `FUN-005`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | Microservice database IOPS & size metrics | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-007`](ADR-007-redis-deployment.md) | Redis Deployment Strategy | `Deferred` | `FUN-008`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | Cache memory footprint & IOPS profiling | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-008`](ADR-008-rabbitmq-deployment.md) | RabbitMQ Deployment Strategy | `Deferred` | `FUN-006`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | Message throughput & queue depth metrics | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-009`](ADR-009-mongodb-deployment.md) | MongoDB Deployment Strategy | `Deferred` | `FUN-007`, `CST-001` | `RSK-DAT-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | MongoDB query/driver DocumentDB compatibility audit | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-010`](ADR-010-nacos-deployment.md) | Nacos Deployment Strategy | `Proposed` | `FUN-009`, `OPS-001` | `RSK-ARC-002` | `ADR-003` | Nacos cross-namespace DNS resolution test | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-011`](ADR-011-secrets-management.md) | Secrets Management Topology | `Proposed` | `SEC-001`, `FUN-002`–`FUN-004` | `RSK-SEC-001`, `RSK-SEC-002` | `ADR-001`, `ADR-003` | External Secrets Operator sync test | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-012`](ADR-012-observability.md) | Observability Architecture | `Proposed` | `OPS-001`, `OPS-002` | `RSK-CST-002`, `RSK-OPS-002` | `ADR-001`, `ADR-003` | Fluent Bit log forwarding benchmark | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-013`](ADR-013-backup-strategy.md) | Backup Strategy | `Proposed` | `NFR-003`, `OPS-002` | `RSK-DAT-002` | `ADR-006`–`ADR-010` | Automated database & Velero restore test | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-014`](ADR-014-disaster-recovery.md) | Disaster Recovery Strategy | `Deferred` | `NFR-003`, `CST-001` | `RSK-UNC-003`, `RSK-AVL-001` | `ADR-001`, `ADR-013` | Business system RTO/RPO target sign-off | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-015`](ADR-015-infrastructure-as-code.md) | Infrastructure as Code Model | `Proposed` | `BUS-002`, `AGENTS.md` | `RSK-DEL-001` | `ADR-001` | Terraform module linting & dry-run audit | Stage 3 / Phase 1 | 2026-08-03 |
