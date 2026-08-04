# ADR-008 — RabbitMQ Deployment Strategy

## Metadata
* **Status**: `Deferred`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Data Architect, Cloud Infrastructure Lead
* **Reviewers**: Enterprise Architecture Board, DevOps Lead
* **Related Requirements**: [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-UNC-001` (Missing message volume data), `RSK-OPS-001` (Message broker stateful complexity)
* **Related Assumptions**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 3, Section 6
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `FUN-006` specifies RabbitMQ message broker services for asynchronous event streaming and inter-service messaging across business systems. We must determine whether to deploy RabbitMQ via the official K8s Cluster Operator on EKS, Amazon MQ for RabbitMQ, or a dedicated EC2 cluster. Message throughput (msg/sec), queue persistence, and payload size metrics are currently unconfirmed (`OPEN-001`).

---

## Decision Drivers
1. **Quorum Queue Resiliency**: Multi-AZ message mirroring and persistent queue durability (`NFR-001`).
2. **Message Throughput & Latency**: Low-latency AMQP 0-9-1 / MQTT message delivery (`FUN-006`).
3. **Operational Overhead**: Managing Erlang VM upgrades, cluster network partitions (split-brain remediation), and queue disk usage.
4. **Cost Architecture**: Comparing Amazon MQ managed broker costs against EKS compute/EBS storage costs (`CST-001`).

---

## Constraints
* Must support standard AMQP protocol and RabbitMQ Quorum Queues.

---

## Options Considered

### Option 1: RabbitMQ on EKS (Official RabbitMQ Cluster Kubernetes Operator)
* **Description**: Deploying RabbitMQ stateful sets using the official VMware/RabbitMQ Cluster Operator on EKS backed by EBS `gp3` volumes across 3 AZs.
* **Advantages**: Declarative custom resource definitions (CRDs); native Kubernetes integration; no Amazon MQ managed instance fee; easy local development parity.
* **Disadvantages**: SRE team must monitor Erlang Mnesia database state, handle network partition recovery, and manage EBS storage expansion.
* **Security Implications**: Good. TLS transport encryption, pod SecurityContext, and IAM IRSA integrations.
* **Availability Implications**: Strong when configured with Quorum Queues across 3 AZs.
* **Scalability Implications**: Dynamic pod scaling and storage volume expansion.
* **Operational Implications**: Moderate-High operational responsibility for Erlang VM tuning (`RSK-OPS-001`).
* **Cost Implications**: Highly cost-effective (uses existing EKS worker node compute/storage).
* **Vendor Lock-in**: Very Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Available EKS compute capacity and EBS `gp3` storage driver.
* **Risks**: Erlang network partition split-brain issues during inter-AZ network spikes.

### Option 2: Amazon MQ for RabbitMQ (Managed Service)
* **Description**: Utilizing AWS managed Amazon MQ service for RabbitMQ in a Multi-AZ active/standby or cluster deployment.
* **Advantages**: AWS manages broker provisioning, OS/Erlang patching, setup, and multi-AZ replication.
* **Disadvantages**: Substantially higher hourly instance pricing; limited underlying Erlang VM configuration access; queue storage size limitations depending on instance type.
* **Security Implications**: Excellent. KMS encryption at rest, TLS in transit, VPC security group isolation.
* **Availability Implications**: High (99.9% SLA).
* **Scalability Implications**: Vertical instance scaling requires broker maintenance windows.
* **Operational Implications**: Minimal operational maintenance required from DevOps team.
* **Cost Implications**: High monthly AWS managed broker fees.
* **Vendor Lock-in**: Low-Moderate (Standard AMQP protocol compatible).
* **Migration Complexity**: Low.
* **Reversibility**: Reversible with migration.
* **Preconditions**: Dedicated VPC subnets.
* **Risks**: High cost growth if message volume expands rapidly.

### Option 3: Dedicated EC2 Cluster for RabbitMQ
* **Description**: Provisioning dedicated EC2 instances running RabbitMQ clusters managed via Ansible.
* **Advantages**: Decouples message broker state entirely from Kubernetes cluster lifecycles.
* **Disadvantages**: Requires manual EC2 instance lifecycle management, OS patching, and custom Ansible maintenance scripts.
* **Security Implications**: Moderate.
* **Availability Implications**: Moderate.
* **Scalability Implications**: Manual EC2 instance provisioning.
* **Operational Implications**: High operational overhead.
* **Cost Implications**: Moderate.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Moderate.
* **Reversibility**: Reversible.
* **Preconditions**: Ansible configuration management scripts (`FUN-004`).
* **Risks**: Manual maintenance error during OS patching.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: RabbitMQ on EKS Operator | Option 2: Amazon MQ for RabbitMQ | Option 3: Dedicated EC2 |
| :--- | :--- | :--- | :--- |
| **Operational Labor** | Moderate | **Minimal** | Heavy |
| **K8s Integration (`BUS-002`)** | **Strong (Native Operator)** | Moderate (AMQP endpoint) | Moderate |
| **Cost Efficiency (`CST-001`)** | **High** | Low (High AWS Premium) | Moderate |
| **Resiliency (Quorum Queues)** | **Strong** | Strong | Moderate |
| **Reversibility** | **Easily Reversible** | Reversible | Reversible |

---

## Proposed Decision
**Decision Deferred**.

---

## Rationale
The choice between RabbitMQ Cluster Operator on EKS (Option 1) and Amazon MQ for RabbitMQ (Option 2) is **deferred pending message volume and throughput metrics** (`OPEN-001`).

Option 1 is currently the leading technical candidate due to standard Operator maturity and cost efficiency, but requires verification against customer message durability targets.

---

## Validation Evidence Required Before Acceptance
1. Microservice message volume (msg/sec), average payload size, and queue persistence targets (`OPEN-001`).
2. SRE team RabbitMQ / Erlang VM operational capability assessment.

## Acceptance Conditions
* Submission of verified messaging benchmarks and formal Architecture Board sign-off.

## Revisit Triggers
* Completion of Phase 1 workload profiling.

## Implementation Implications
* Platform architecture allocates EKS namespace and network endpoints for RabbitMQ routing.
