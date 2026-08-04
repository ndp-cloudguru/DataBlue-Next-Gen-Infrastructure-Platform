# ADR-010 — Nacos Deployment Strategy

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Application Architect, DevOps Lead
* **Reviewers**: Enterprise Architecture Board
* **Related Requirements**: [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-ARC-002` (Nacos cluster state synchronization failure)
* **Related Assumptions**: [`ASM-001`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 3, Section 6
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `FUN-009` specifies Nacos for microservice service discovery, dynamic configuration management, and health checking across the ~40 microservices. We must decide whether to deploy Nacos directly inside EKS, on dedicated EC2 instances, or replace it with alternative tooling.

---

## Decision Drivers
1. **Low-Latency Inter-Service Discovery**: Sub-second DNS / API lookup for microservices registering with Nacos (`FUN-009`).
2. **High Availability & Quorum State**: Multi-AZ Nacos cluster raft quorum synchronization (`NFR-001`).
3. **Requirement Compliance**: Direct customer requirement for Nacos compatibility without application refactoring.

---

## Constraints
* Must host Nacos 2.x+ cluster mode with MySQL backend support.

---

## Options Considered

### Option 1: Nacos Cluster Deployed on EKS (Private Application Subnets)
* **Description**: Deploying Nacos as a multi-replica StatefulSet inside EKS across 3 AZs in Private Application Subnets, backed by the MySQL database tier for persistent configuration storage.
* **Advantages**: Sub-millisecond intra-cluster communication with microservice pods; automated pod lifecycle management via Kubernetes Deployment/StatefulSet; zero separate EC2 instance overhead.
* **Disadvantages**: Microservice service registration depends on EKS cluster DNS resolution stability.
* **Security Implications**: Strong. Isolated within private subnets; Kubernetes NetworkPolicies restrict ingress strictly to microservice namespaces.
* **Availability Implications**: High. 3-node Nacos Raft cluster spread across 3 AZs.
* **Scalability Implications**: Easy pod replica scaling.
* **Operational Implications**: Standard Kubernetes workload maintenance.
* **Cost Implications**: Low (runs on existing EKS worker node compute).
* **Vendor Lock-in**: Very Low (Open-source Nacos).
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: MySQL relational database availability (`FUN-005`).
* **Risks**: `RSK-ARC-002` (Nacos Raft leader election instability during node failovers).

### Option 2: Dedicated EC2 Cluster for Nacos
* **Description**: Deploying Nacos on a standalone 3-node EC2 cluster managed via Ansible.
* **Advantages**: Isolates service discovery control plane from EKS cluster reschedules.
* **Disadvantages**: Higher monthly AWS EC2 instance costs; manual OS patching and node maintenance.
* **Security Implications**: Moderate. Requires VPC security group management.
* **Availability Implications**: High.
* **Scalability Implications**: Manual EC2 instance resizing.
* **Operational Implications**: Heavy manual operational overhead.
* **Cost Implications**: Substantially higher (3 dedicated EC2 instances per environment).
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Reversible.
* **Preconditions**: Ansible playbooks (`FUN-004`).
* **Risks**: Manual maintenance errors during OS updates.

### Option 3: Alternative Managed Configuration (AWS AppConfig + CoreDNS)
* **Description**: Replacing Nacos entirely with AWS AppConfig for dynamic configuration and CoreDNS for service discovery.
* **Advantages**: AWS managed serverless configuration service.
* **Disadvantages**: Violates requirement `FUN-009`; requires refactoring all ~40 microservice SDK integrations.
* **Security Implications**: Excellent.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: Low.
* **Cost Implications**: AppConfig API call pricing.
* **Vendor Lock-in**: High (AWS AppConfig proprietary API).
* **Migration Complexity**: High (Microservice code rewriting).
* **Reversibility**: Difficult.
* **Preconditions**: Customer waiver of Nacos requirement.
* **Risks**: High application refactoring cost.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Nacos on EKS | Option 2: Dedicated EC2 | Option 3: AWS AppConfig |
| :--- | :--- | :--- | :--- |
| **Requirement Compliance (`FUN-009`)** | **100% Compliant** | **100% Compliant** | Non-Compliant |
| **Latency & In-Cluster Connectivity** | **Sub-Millisecond** | Moderate | Moderate |
| **Cost Efficiency (`CST-001`)** | **High** | Low (Dedicated EC2) | Moderate |
| **Operational Labor** | Low | High | Minimal |
| **Reversibility** | **Easily Reversible** | Reversible | Difficult |

---

## Proposed Decision
**Option 1: Nacos Cluster Deployed on EKS (Private Application Subnets)**.

---

## Rationale
Option 1 fulfills requirement `FUN-009` without application code refactoring, delivers sub-millisecond latency for in-cluster microservices, and avoids the unnecessary cost of dedicated EC2 instances.

---

## Consequences
* **Positive**: 100% functional requirement compliance; minimal operational cost; native EKS pod network performance.
* **Negative**: Depends on MySQL database tier for configuration persistence.
* **New Operational Responsibilities**: Monitoring Nacos Raft cluster health and database connection pools.
* **New Risks**: `RSK-ARC-002` (Raft leader election latency during node reboots).
* **Cost Consequences**: Zero additional infrastructure cost (uses EKS worker capacity).

---

## Validation Evidence
* Nacos cluster multi-AZ deployment test and cross-namespace DNS resolution verification.

## Acceptance Conditions
* Lead Application Architect and DevOps Lead sign-off.

## Revisit Triggers
* Discovery of severe inter-pod latency during Nacos Raft synchronization.

## Implementation Implications
* Nacos Helm chart / K8s manifests deployed to EKS private application subnets in Phase 3.
