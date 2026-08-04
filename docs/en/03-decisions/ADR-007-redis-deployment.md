# ADR-007 — Redis Deployment Strategy

## Metadata
* **Status**: `Deferred`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Data Architect, Cloud Infrastructure Lead
* **Reviewers**: Enterprise Architecture Board, FinOps Team
* **Related Requirements**: [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-UNC-001` (Missing cache memory metrics), `RSK-OPS-001` (Self-hosted cache operational maintenance)
* **Related Assumptions**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 3, Section 6
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `FUN-008` specifies an in-memory Redis cache for transient session storage and high-speed data caching across the microservices. We must evaluate whether to deploy Redis inside EKS or leverage Amazon ElastiCache for Redis. Cache memory capacity, eviction rates, and hit/miss ratios are currently unconfirmed (`OPEN-001`).

---

## Decision Drivers
1. **Sub-Millisecond Latency**: Guaranteeing low-latency cache reads/writes (`FUN-008`).
2. **High Availability & Cache Persistence**: Multi-AZ failover and data replication without cache data loss during node reboots (`NFR-001`).
3. **Operational Simplicity**: Eliminating manual Redis cluster sharding and slot migration maintenance.
4. **Cost Optimization**: Balancing AWS managed cache hourly node fees against worker node RAM consumption (`CST-001`).

---

## Constraints
* Must support standard Redis 7.0+ API protocol.

---

## Options Considered

### Option 1: Self-Hosted Redis Cluster on EKS (Bitnami Helm / Redis Operator)
* **Description**: Hosting Redis Sentinel or Redis Cluster pods inside EKS using Kubernetes worker node RAM backed by ephemeral or EBS storage.
* **Advantages**: Zero ElastiCache managed service premium; full control over Redis configuration parameters; total cloud portability.
* **Disadvantages**: Consumes expensive worker node RAM; pod reschedules trigger cache cold-starts or re-sharding overhead; requires manual cluster slot management.
* **Security Implications**: Moderate. TLS encryption and network policies configured manually.
* **Availability Implications**: Moderate. Pod failures cause transient cache misses until failover completes.
* **Scalability Implications**: Requires manual StatefulSet RAM allocation adjustments.
* **Operational Implications**: SRE team must manage cluster failovers and node maintenance (`RSK-OPS-001`).
* **Cost Implications**: Utilizes existing EKS worker node RAM capacity.
* **Vendor Lock-in**: Very Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Available worker node RAM allocation.
* **Risks**: `RSK-OPS-001` (Cache pod eviction causing cascading database overload).

### Option 2: Amazon ElastiCache for Redis (Multi-AZ Replication Group)
* **Description**: Fully managed, dedicated Amazon ElastiCache Redis cluster deployed across multiple Availability Zones with automatic failover.
* **Advantages**: Sub-millisecond latency; automatic multi-AZ failover (< 30 seconds); offloads memory management from EKS worker nodes; managed security patching.
* **Disadvantages**: Dedicated hourly node pricing (`cache.m6g` instances); potential cross-AZ data transfer fees.
* **Security Implications**: Excellent. KMS encryption at rest, TLS transit encryption, IAM auth.
* **Availability Implications**: Strong (99.99% SLA).
* **Scalability Implications**: Easy online cluster scaling and shard expansion.
* **Operational Implications**: Minimal operational burden on DevOps team.
* **Cost Implications**: Moderate fixed monthly AWS spend.
* **Vendor Lock-in**: Low-Moderate (Standard Redis protocol compatible).
* **Migration Complexity**: Low.
* **Reversibility**: Reversible with migration.
* **Preconditions**: Dedicated Database VPC Subnets.
* **Risks**: Over-provisioning cache node memory before workload profiling.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Redis on EKS | Option 2: Amazon ElastiCache for Redis |
| :--- | :--- | :--- |
| **Latency & SLA** | Moderate-High | **Sub-Millisecond (99.99%)** |
| **Operational Labor** | High | **Minimal** |
| **Worker Node RAM Contention** | High Risk | **Zero Contention** |
| **Cost Predictability** | High | Moderate |
| **Reversibility** | **Easily Reversible** | Reversible |

---

## Proposed Decision
**Decision Deferred**.

---

## Rationale
The decision between Amazon ElastiCache for Redis and Self-Hosted Redis on EKS is **deferred pending microservice cache memory profiling** (`OPEN-001`). 

If aggregate cache RAM requirement is small (< 4 GB), self-hosting on EKS may be cost-effective; if cache requirements exceed 16 GB with high concurrency, ElastiCache is required to protect worker node stability.

---

## Validation Evidence Required Before Acceptance
1. Microservice cache memory footprint, TTL eviction policy, and query RPS metrics (`OPEN-001`).
2. FinOps cost threshold approval.

## Acceptance Conditions
* Submission of verified cache memory benchmarks and Architecture Board review.

## Revisit Triggers
* Completion of Phase 1 workload profiling.

## Implementation Implications
* Network design allocates dedicated DB subnets capable of hosting either option.
