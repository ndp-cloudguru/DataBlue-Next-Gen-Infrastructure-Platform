# ADR-009 — MongoDB Deployment Strategy

## Metadata
* **Status**: `Deferred`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Data Architect, Cloud Security Lead
* **Reviewers**: Enterprise Architecture Board, Application Development Lead
* **Related Requirements**: [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-DAT-001` (Amazon DocumentDB wire-protocol incompatibility), `RSK-OPS-001` (Self-hosted NoSQL operational complexity)
* **Related Assumptions**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 3, Section 6
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `FUN-007` mandates MongoDB document database services for unstructured data persistence. We must evaluate deployment strategies: MongoDB Operator on EKS, MongoDB Atlas on AWS, Amazon DocumentDB, or a dedicated EC2 MongoDB cluster. **Crucially, Amazon DocumentDB is not fully MongoDB wire-compatible**, lacking support for specific aggregation pipelines, change stream operators, and index types.

---

## Decision Drivers
1. **Wire-Protocol Compatibility**: 100% compatibility with application MongoDB driver queries and aggregation pipelines (`FUN-007`).
2. **Replica Set High Availability**: Multi-AZ primary/secondary replica set failover (`NFR-001`).
3. **Operational Overhead**: Automated backup, storage scaling, and replica set recovery (`NFR-003`).
4. **Licensing & TCO**: Server Side Public License (SSPL) compliance vs. AWS DocumentDB pricing (`CST-001`).

---

## Constraints
* Must support document storage for microservices without requiring microservice code rewrites.

---

## Options Considered

### Option 1: MongoDB Community / Enterprise Operator on EKS
* **Description**: Deploying native MongoDB replica sets on EKS using the official MongoDB Kubernetes Operator backed by EBS `gp3` storage across 3 AZs.
* **Advantages**: 100% genuine MongoDB wire-protocol compatibility; zero proprietary cloud database lock-in; complete control over SSPL licensing and feature sets.
* **Disadvantages**: Team must manage replica set member elections, EBS storage expansion, backup automation, and node maintenance.
* **Security Implications**: Good. TLS encryption, SCRAM authentication, KMS volume encryption.
* **Availability Implications**: Strong when deployed as a 3-member replica set across 3 AZs.
* **Scalability Implications**: Manual replica set member additions and storage volume resizing.
* **Operational Implications**: Heavy ongoing operational burden for DBA / SRE team (`RSK-OPS-001`).
* **Cost Implications**: Highly cost-effective (uses existing EKS node compute and EBS storage).
* **Vendor Lock-in**: Very Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Available EBS `gp3` storage driver and DBA operational capability.
* **Risks**: `RSK-OPS-001` (Unintended replica set primary election failures during node maintenance).

### Option 2: MongoDB Atlas on AWS (Managed SaaS)
* **Description**: Fully managed MongoDB Atlas database clusters hosted natively on AWS infrastructure.
* **Advantages**: 100% genuine MongoDB compatibility backed directly by MongoDB Inc.; fully managed multi-AZ scaling, automated backups, and security patching.
* **Disadvantages**: Requires third-party SaaS vendor agreement; potential VPC peering / AWS PrivateLink setup complexity.
* **Security Implications**: Excellent. AWS PrivateLink isolation, KMS encryption, granular audit logs.
* **Availability Implications**: Excellent (99.99% SLA).
* **Scalability Implications**: Excellent online cluster auto-scaling.
* **Operational Implications**: Minimal operational burden.
* **Cost Implications**: Premium managed SaaS monthly pricing.
* **Vendor Lock-in**: Moderate (MongoDB technology lock-in).
* **Migration Complexity**: Low.
* **Reversibility**: Reversible.
* **Preconditions**: Third-party SaaS procurement approval.
* **Risks**: Third-party SaaS vendor dependency (`RSK-VND-001`).

### Option 3: Amazon DocumentDB (with MongoDB Compatibility)
* **Description**: AWS proprietary document database service designed to emulate MongoDB 3.6/4.0/5.0 APIs.
* **Advantages**: Fully managed by AWS; integrated with AWS IAM, CloudWatch, and KMS; distributed multi-AZ storage.
* **Disadvantages**: **INCOMPLETE MONGODB WIRE-PROTOCOL COMPATIBILITY**. Lacks support for specific aggregation stages (e.g. `$lookup` limitations), change stream features, and specific indexing types.
* **Security Implications**: Excellent. Native AWS IAM, KMS, and CloudWatch integration.
* **Availability Implications**: Excellent (99.99% SLA).
* **Scalability Implications**: Excellent storage scaling up to 128TB.
* **Operational Implications**: Minimal management overhead.
* **Cost Implications**: High monthly AWS managed database spend.
* **Vendor Lock-in**: High (AWS DocumentDB storage engine lock-in).
* **Migration Complexity**: High if application code uses unsupported MongoDB syntax.
* **Reversibility**: Difficult if application code adapts to DocumentDB quirks.
* **Preconditions**: **MANDATORY AUDIT of all microservice database queries against DocumentDB feature matrices**.
* **Risks**: `RSK-DAT-001` (Application driver runtime failures due to unsupported MongoDB syntax).

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: MongoDB on EKS | Option 2: MongoDB Atlas | Option 3: Amazon DocumentDB |
| :--- | :--- | :--- | :--- |
| **MongoDB Wire Compatibility** | **100% (Native)** | **100% (Native)** | **UNVERIFIED (< 100%)** |
| **Operational Labor** | Heavy | **Minimal** | **Minimal** |
| **Vendor Independence** | **Very High** | Moderate | Low (AWS Lock-in) |
| **Cost Efficiency (`CST-001`)** | **High** | Moderate | Low (High AWS Fee) |
| **Reversibility** | **Easily Reversible** | Reversible | Difficult |

---

## Proposed Decision
**Decision Deferred**.

---

## Rationale
The decision is **deferred pending an empirical compatibility audit of application MongoDB queries against Amazon DocumentDB feature matrices** (`RSK-DAT-001`).

Claiming Amazon DocumentDB can seamlessly replace MongoDB without evidence is prohibited under governance rules. If microservices require unsupported MongoDB features, Option 1 (MongoDB Operator on EKS) or Option 2 (MongoDB Atlas) will be selected.

---

## Validation Evidence Required Before Acceptance
1. Automated query/driver compatibility scan of microservice source code against DocumentDB API support limits (`RSK-DAT-001`).
2. Microservice document storage capacity and IOPS profiling (`OPEN-001`).

## Acceptance Conditions
* Completion of DocumentDB compatibility audit and Lead Data Architect sign-off.

## Revisit Triggers
* Discovery of incompatible MongoDB aggregation pipelines during Phase 1 code review.

## Implementation Implications
* Platform architecture allocates isolated database subnets capable of supporting EKS pods or PrivateLink endpoints.
