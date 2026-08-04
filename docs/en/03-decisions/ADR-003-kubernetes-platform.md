# ADR-003 — Kubernetes Platform Engine

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Cloud Architect, DevOps Lead
* **Reviewers**: Enterprise Architecture Board
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-OPS-001` (Control plane operational maintenance overhead)
* **Related Assumptions**: [`ASM-003`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 6
* **Supersedes**: None
* **Superseded By**: None

---

## Context
The platform requires a production-grade Kubernetes container runtime to orchestrate ~40 microservices (`FUN-001`). We must select the underlying Kubernetes control plane deployment and management engine.

---

## Decision Drivers
1. **Control Plane Resiliency & Availability**: Guaranteeing multi-AZ control plane uptime without manual etcd quorum management (`NFR-001`).
2. **AWS Native Service Integration**: Seamless integration with AWS IAM (IRSA), VPC CNI, AWS KMS, and AWS ALB Ingress Controllers (`SEC-001`).
3. **Operational Maintenance Overhead**: Minimizing team overhead required for control plane patching, master node OS upgrades, and backup/restore.

---

## Constraints
* Infrastructure must be provisioned natively on AWS.

---

## Options Considered

### Option 1: Self-Managed Kubernetes on EC2 (kOps / kubeadm)
* **Description**: Deploying and managing etcd nodes and API server master EC2 instances manually using kOps or kubeadm scripts.
* **Advantages**: Zero EKS control plane fee ($0.10/hr saving); full access to Kubernetes API server flags.
* **Disadvantages**: Extreme operational complexity; team must manage etcd quorum backups, OS patching, control plane multi-AZ failover, and manual upgrades.
* **Security Implications**: High risk of unpatched control plane vulnerabilities or misconfigured etcd encryption.
* **Availability Implications**: Moderate-Weak unless dedicated SRE team maintains 24/7 etcd quorum monitoring.
* **Scalability Implications**: Manual master node resizing required during high cluster load.
* **Operational Implications**: Heavy ongoing labor cost and operational burden (`RSK-OPS-001`).
* **Cost Implications**: Saves ~$73/month control plane fee, but significantly increases SRE labor costs.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: High.
* **Reversibility**: Difficult.
* **Preconditions**: Dedicated SRE team with deep Kubernetes control plane expertise.
* **Risks**: `RSK-OPS-001` (Severe operational burden and etcd corruption risk).

### Option 2: Amazon EKS (AWS Managed Kubernetes Control Plane)
* **Description**: Utilizing Amazon EKS, where AWS manages control plane availability, etcd encryption, and multi-AZ master node scaling.
* **Advantages**: SLA-backed 99.95% control plane uptime; automated etcd management; native AWS IAM IRSA integration; managed node group capabilities.
* **Disadvantages**: $0.10/hr ($73/month) control plane cost per cluster; AWS controls master node version upgrade timelines.
* **Security Implications**: Excellent. Integrated AWS KMS etcd encryption and IAM OIDC authentication (`SEC-001`).
* **Availability Implications**: Excellent. Multi-AZ active-active control plane provisioned automatically.
* **Scalability Implications**: Excellent. Control plane auto-scales based on API request throughput.
* **Operational Implications**: Minimal control plane management overhead.
* **Cost Implications**: Predictable $0.10/hr fee per cluster.
* **Vendor Lock-in**: Moderate (Native AWS EKS integrations).
* **Migration Complexity**: Low (Standard Kubernetes API compatibility).
* **Reversibility**: Easily Reversible.
* **Preconditions**: None.
* **Risks**: AWS version deprecation cycles (requires annual cluster upgrades).

### Option 3: Alternative Managed Platform (Red Hat OpenShift on AWS - ROSA)
* **Description**: Managed Red Hat OpenShift platform running on AWS infrastructure.
* **Advantages**: Enterprise developer portal, built-in CI/CD pipelines, and integrated service mesh out-of-the-box.
* **Disadvantages**: Substantially higher licensing costs (Red Hat subscription fees); rigid platform opinionation.
* **Security Implications**: Strong enterprise compliance capabilities.
* **Availability Implications**: High. Managed by AWS and Red Hat.
* **Scalability Implications**: High.
* **Operational Implications**: Requires OpenShift-specific operational knowledge.
* **Cost Implications**: Very high licensing costs compared to standard EKS.
* **Vendor Lock-in**: High (Red Hat OpenShift platform lock-in).
* **Migration Complexity**: High.
* **Reversibility**: Difficult.
* **Preconditions**: Red Hat subscription agreement.
* **Risks**: High software licensing cost.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Self-Managed on EC2 | Option 2: Amazon EKS | Option 3: Red Hat ROSA |
| :--- | :--- | :--- | :--- |
| **Control Plane HA & SLA** | Weak | **Strong** | **Strong** |
| **AWS IAM / VPC Integration** | Moderate | **Strong** | Moderate |
| **Operational Simplicity** | Weak | **Strong** | Moderate |
| **Cost Efficiency** | Moderate (High Labor) | **Strong** | Weak (High License) |
| **Reversibility** | Difficult | **Easily Reversible** | Difficult |

---

## Proposed Decision
**Option 2: Amazon EKS (AWS Managed Kubernetes Control Plane)**.

---

## Rationale
Amazon EKS eliminates control plane management overhead (`RSK-OPS-001`), delivers native AWS IAM/VPC integration, and provides standard upstream Kubernetes API compatibility at a fraction of the cost of proprietary alternatives.

---

## Consequences
* **Positive**: 99.95% control plane SLA; minimal SRE maintenance labor; native IRSA integration.
* **Negative**: $0.10/hr control plane fee per environment cluster.
* **New Operational Responsibilities**: Tracking AWS EKS version support lifecycle and planning annual cluster upgrades.
* **New Risks**: EKS API version deprecations.
* **Cost Consequences**: ~$146/month for Test + Prod control plane management fees.

---

## Validation Evidence
* AWS EKS service SLA documentation and IAM OIDC IRSA integration audit.

## Acceptance Conditions
* Enterprise Architecture Board sign-off.

## Revisit Triggers
* EKS control plane cost model changes or multi-cloud portability requirements.

## Implementation Implications
* EKS control plane provisioned via standard Terraform EKS module in Phase 3.
