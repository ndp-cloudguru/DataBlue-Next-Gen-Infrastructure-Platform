# Dependency Map: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies technical, organizational, evidence, and governance dependencies for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

Dependencies are classified into five categories:
1. **Hard Dependencies**: Technical prerequisites that physically block downstream execution.
2. **Soft Dependencies**: Best-practice sequences that improve efficiency but do not strictly prevent execution.
3. **External Dependencies**: Customer inputs, third-party vendor APIs, or organizational approvals.
4. **Human Approval Dependencies**: Governance gates requiring formal human sign-off (`ACCEPTANCE-GATES.md`).
5. **Evidence Dependencies**: Empirical benchmarks, profiling data, or audits required to unblock decisions.

---

## 2. Master Dependency Graph (Mermaid)

```mermaid
graph TD
    P0["Phase 0: Evidence Collection"] --> G01["GATE-01: Requirement Baseline"]
    G01 --> G03["GATE-03: ADR Approval"]
    G03 --> P1["Phase 1: AWS Foundation"]
    
    P1 --> G04["GATE-04: AWS Foundation Ready"]
    G04 --> P2["Phase 2: Test Platform Build"]
    
    P2 --> G05["GATE-05: Test Platform Ready"]
    G05 --> P3["Phase 3: Shared Services Installation"]
    G05 --> P4["Phase 4: CI/CD Integration"]
    
    P3 --> P5["Phase 5: Stateful Middleware Delivery"]
    P4 --> P5
    
    P5 --> P6["Phase 6: Technical Pilot Onboarding"]
    P6 --> G06["GATE-06: Technical Pilot Accepted"]
    
    G06 --> G07["GATE-07: Production Build Approval CAB"]
    G07 --> P7["Phase 7: Production Platform Construction"]
    
    P7 --> P8["Phase 8: Migration Waves 1-5"]
    P8 --> G09["GATE-09: Migration Wave Sign-Off"]
    
    G09 --> P9["Phase 9: Production Readiness & Chaos DR"]
    P9 --> G08["GATE-08: Production Readiness Accepted"]
    
    G08 --> P10["Phase 10: Operational Handover"]
    P10 --> G10["GATE-10: Handover Acceptance"]

    classDef gate fill:#f9f,stroke:#333,stroke-width:2px;
    classDef hard fill:#bbf,stroke:#333,stroke-width:1px;
    classDef evid fill:#ffd,stroke:#333,stroke-width:1px;

    class G01,G03,G04,G05,G06,G07,G08,G09,G10 gate;
    class P1,P2,P3,P4,P5,P6,P7,P8,P9,P10 hard;
    class P0 evid;
```

---

## 3. Detailed Dependency Matrix

### 1. Evidence Dependencies
* `DEP-EVD-001`: **Microservice Sizing Profiling Data** (`OPEN-001`) → Required to unblock [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) (MySQL), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) (Redis), [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md) (RabbitMQ), and `WP-011`–`WP-012`.
* `DEP-EVD-002`: **DocumentDB MongoDB Wire Compatibility Audit** (`RSK-DAT-001`) → Required to unblock [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md) (MongoDB).
* `DEP-EVD-003`: **Business Continuity RTO/RPO Sign-off** (`OPEN-003`) → Required to unblock [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) (Disaster Recovery).

### 2. Human Approval Dependencies
* `DEP-HUM-001`: [`GATE-03`](ACCEPTANCE-GATES.md) **ADR Sign-off** → Human review of Proposed ADRs (`ADR-001`..`015`) required before Phase 1 foundation execution (`WP-002`).
* `DEP-HUM-002`: [`GATE-07`](ACCEPTANCE-GATES.md) **CAB Production Approval** → Change Advisory Board authorization required before creating `DataBlue-Prod-Account` (`WP-015`).
* `DEP-HUM-003`: [`GATE-10`](ACCEPTANCE-GATES.md) **Handover Acceptance** → Operations Lead sign-off required for project completion (`WP-020`).

### 3. Hard Technical Dependencies
* `DEP-TRC-001`: **Multi-Account Landing Zone (`WP-002`)** → Hard prerequisite for VPC Networking (`WP-004`) and Test EKS cluster (`WP-005`).
* `DEP-TRC-002`: **Test EKS Cluster (`WP-005`)** → Hard prerequisite for Shared Platform Services (`WP-007`..`WP-009`) and CI/CD pipelines (`WP-010`).
* `DEP-TRC-003`: **MySQL Database Tier (`WP-011`)** → Hard prerequisite for Nacos Cluster deployment (`WP-013`).
* `DEP-TRC-004`: **Test Environment Validation (`WP-014`)** → Hard prerequisite for Production Cluster Construction (`WP-015`).

### 4. External Dependencies
* `DEP-EXT-001`: **AWS Account Quotas & Domain Registrations** → Customer AWS Organizations root permission and Cloudflare public domain & DNS access.
* `DEP-EXT-002`: **GitLab & Jenkins Legacy Repositories** → Customer developer access permissions to source code repositories.
