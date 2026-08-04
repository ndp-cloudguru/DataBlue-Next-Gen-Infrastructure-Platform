# ADR-005 — Node Autoscaling Engine

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Cloud Architect, Infrastructure Engineer
* **Reviewers**: Enterprise Architecture Board, FinOps Team
* **Related Requirements**: [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-SCL-001` (Slow node provisioning latency), `RSK-CST-001` (Uncontrolled node autoscaling costs)
* **Related Assumptions**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 10
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `NFR-002` specifies dynamic node-level infrastructure scaling for the EKS cluster hosting ~40 microservices. Sizing metrics are currently unavailable (`OPEN-001`). We must select an autoscaling engine that dynamically matches node capacity to pod scheduling demand without manual capacity management.

---

## Decision Drivers
1. **Provisioning Latency**: Fast reaction time to scale node capacity when unschedulable pods are pending (`NFR-002`).
2. **Cost Optimization & Rightsizing**: Selecting the exact EC2 instance size and type matching pending pod resource requests, avoiding node bin-packing waste (`CST-001`).
3. **Operational Simplicity**: Eliminating the overhead of manually pre-defining EC2 Auto Scaling Groups (ASGs) for various CPU/RAM instance tiers.

---

## Constraints
* Must run natively within Amazon EKS.

---

## Options Considered

### Option 1: Static EC2 Node Capacity (No Autoscaling)
* **Description**: Provisioning a fixed number of EC2 instances per node group based on estimated peak load.
* **Advantages**: Simple configuration; zero autoscaling logic bugs.
* **Disadvantages**: Severe cost over-spending during off-peak traffic; risk of cluster out-of-memory crashes during unexpected traffic surges.
* **Security Implications**: Neutral.
* **Availability Implications**: Weak during traffic spikes.
* **Scalability Implications**: Zero dynamic node scaling (`NFR-002` failure).
* **Operational Implications**: Requires manual SRE intervention to scale EC2 instance count.
* **Cost Implications**: Extremely inefficient (high monthly AWS waste).
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: None.
* **Risks**: `RSK-SCL-001` (Pod unschedulable failures during peak load).

### Option 2: Managed Node Groups with Kubernetes Cluster Autoscaler (CAS)
* **Description**: Utilizing standard Kubernetes Cluster Autoscaler, which monitors pending pods and increments the desired capacity of AWS Auto Scaling Groups (ASGs).
* **Advantages**: Well-established, battle-tested Kubernetes standard; supported natively by EKS Managed Node Groups.
* **Disadvantages**: Slow scaling response (~3-5 minutes per node); constrained by rigid pre-configured ASG instance types; inefficient bin-packing for diverse pod sizes.
* **Security Implications**: Good. Integrated with AWS IAM IRSA.
* **Availability Implications**: Moderate-High.
* **Scalability Implications**: Moderate. Restricted to pre-defined ASG node pools.
* **Operational Implications**: Requires creating and maintaining multiple ASG definitions for different instance sizes.
* **Cost Implications**: Sub-optimal bin-packing efficiency.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Reversible.
* **Preconditions**: EKS Cluster Autoscaler deployment.
* **Risks**: Slow node provisioning latency during rapid microservice scaling events.

### Option 3: EKS Managed Node Groups + Karpenter (Just-in-Time Autoscaler)
* **Description**: Deploying Karpenter, an open-source, high-performance Kubernetes node autoscaler built by AWS that provisions EC2 instances directly without underlying ASGs.
* **Advantages**: Fast provisioning (< 1 minute node launch); dynamic instance selection matching exact pod requests (`c6i`, `m6i`, `r6i`); automatic node consolidation and rightsizing (`CST-001`); seamless Spot instance orchestration for Test environments.
* **Disadvantages**: Requires Karpenter controller lifecycle management and NodePool CRD setup.
* **Security Implications**: Strong. Uses AWS IAM Roles for Service Accounts (IRSA).
* **Availability Implications**: Excellent. Multi-AZ node provisioning based on topology constraints.
* **Scalability Implications**: Excellent. Direct EC2 Fleet API scaling bypassing ASG bottlenecks.
* **Operational Implications**: Eliminates ASG maintenance; requires learning Karpenter NodePool CRDs.
* **Cost Implications**: Highest cost efficiency (saves 15-30% on compute waste via bin-packing).
* **Vendor Lock-in**: Moderate (AWS EC2 Fleet optimization).
* **Migration Complexity**: Low.
* **Reversibility**: Reversible.
* **Preconditions**: EKS OIDC IRSA setup.
* **Risks**: `RSK-UNC-001` (Unverified Spot instance interruption rates in Test).

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Static EC2 | Option 2: Cluster Autoscaler (CAS) | Option 3: Karpenter (JIT) |
| :--- | :--- | :--- | :--- |
| **Provisioning Speed** | None | Moderate (~3-5 min) | **Fast (< 1 min)** |
| **Bin-Packing Efficiency** | Weak | Moderate | **Strong** |
| **ASG Maintenance Overhead** | Manual | High (Multiple ASGs) | **Zero ASG Overhead** |
| **Cost Optimization (`CST-001`)** | Weak | Moderate | **Strong** |
| **Reversibility** | Easily Reversible | Reversible | **Reversible** |

---

## Proposed Decision
**Option 3: EKS Managed Node Groups + Karpenter (Just-in-Time Autoscaler)**.

---

## Rationale
Karpenter provides superior provisioning speed (`NFR-002`), automates dynamic instance selection without ASG overhead, and delivers optimal FinOps bin-packing cost savings (`CST-001`), making it ideal while workload sizing parameters remain unconfirmed.

---

## Consequences
* **Positive**: Rapid node spin-up; automated node consolidation; zero ASG management.
* **Negative**: Team must manage Karpenter NodePool CRD configurations.
* **New Operational Responsibilities**: Monitoring Karpenter controller logs and instance interruption queues.
* **New Risks**: `RSK-CST-001` (Uncontrolled node autoscaling spend if pod resource limits are omitted).
* **Cost Consequences**: Reduced EC2 monthly compute spend via intelligent rightsizing.

---

## Validation Evidence
* Karpenter node provisioning latency benchmark and pod rescheduling consolidation test.

## Acceptance Conditions
* Infrastructure Lead and FinOps Team sign-off.

## Revisit Triggers
* Karpenter controller incompatibility with future EKS API versions.

## Implementation Implications
* Karpenter Helm chart and NodePool CRD manifests provisioned in Phase 3.
