# ADR-015 — Infrastructure as Code Model

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Infrastructure Architect, DevOps Lead
* **Reviewers**: Enterprise Architecture Board, Security Team
* **Related Requirements**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`AGENTS.md`](../../AGENTS.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-DEL-001` (IaC module complexity and state lock contention)
* **Related Assumptions**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 15
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `BUS-002` mandates automated platform deployment. `AGENTS.md` mandates declarative, version-controlled immutable infrastructure. We must select the Infrastructure as Code (IaC) language, state management architecture, and provisioning model for the AWS Kubernetes Platform.

---

## Decision Drivers
1. **Declarative State & Immutability**: 100% of AWS infrastructure (VPCs, subnets, IAM roles, EKS clusters, database instances) provisioned declaratively via code (`BUS-002`).
2. **Modular Reusability & DRY Principles**: Creating reusable infrastructure modules for Test and Production accounts (`ADR-001`, `ADR-002`).
3. **State Locking & Auditability**: Remote state locking via S3 + DynamoDB to prevent concurrent execution state corruption.

---

## Constraints
* Must generate clean, version-controlled code during Phase 3 prototyping.

---

## Options Considered

### Option 1: AWS CloudFormation
* **Description**: Utilizing AWS native CloudFormation JSON/YAML templates.
* **Advantages**: AWS native service; no remote state bucket management required.
* **Disadvantages**: Verbose, rigid YAML syntax; slow execution rollbacks; weak modular abstraction capabilities; limited open-source community module library.
* **Security Implications**: Good. Integrated with AWS IAM.
* **Availability Implications**: High.
* **Scalability Implications**: Moderate. Nested stack complexity.
* **Operational Implications**: High template maintenance burden.
* **Cost Implications**: Zero tool cost.
* **Vendor Lock-in**: High (AWS CloudFormation syntax).
* **Migration Complexity**: High.
* **Reversibility**: Difficult.
* **Preconditions**: None.
* **Risks**: CloudFormation stack drift and rollback locks.

### Option 2: AWS Cloud Development Kit (AWS CDK in TypeScript/Python)
* **Description**: Authoring infrastructure using imperative programming languages (TypeScript/Python) compiled into CloudFormation.
* **Advantages**: Expressive programming syntax; object-oriented construct reuse.
* **Disadvantages**: Imperative code hides underlying infrastructure state; difficult for SREs without software development backgrounds; complex state diff auditing.
* **Security Implications**: Good.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: High requirement for programming language maintenance.
* **Cost Implications**: Zero tool cost.
* **Vendor Lock-in**: High (AWS CDK constructs).
* **Migration Complexity**: High.
* **Reversibility**: Reversible.
* **Preconditions**: Developer proficiency in TypeScript/Python.
* **Risks**: Code abstraction bugs generating unintended CloudFormation diffs.

### Option 3: Pure Modular Terraform / OpenTofu (Infra + K8s Manifests)
* **Description**: Using HCL with Terraform / OpenTofu for both AWS cloud resources and inside-cluster Kubernetes Helm releases via the Terraform Helm provider.
* **Advantages**: Industry-standard HCL syntax; massive open-source module ecosystem; clear `terraform plan` dry-runs (`AGENTS.md`).
* **Disadvantages**: Managing Kubernetes workloads via Terraform Helm provider can cause state drift if developers also apply manifests using `kubectl`.
* **Security Implications**: Excellent. Remote S3 state encryption + DynamoDB locking.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: Moderate.
* **Cost Implications**: Zero open-source tool cost.
* **Vendor Lock-in**: Low (Cloud agnostic syntax).
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: S3 + DynamoDB remote state backend.
* **Risks**: Terraform state file lock contention.

### Option 4: Hybrid Model (Modular Terraform for AWS Infra + Helm/Ansible/GitOps for K8s Workloads)
* **Description**: Clear separation of responsibilities:
  1. **Terraform / OpenTofu**: Provisioning physical AWS cloud infrastructure (VPCs, subnets, IAM IRSA roles, EKS control plane, node groups, KMS keys, database instances).
  2. **Helm / Ansible / ArgoCD**: Provisioning in-cluster Kubernetes applications, Nacos, operators, ingress rules, and microservices (`BUS-002`, `FUN-004`).
* **Advantages**: Clean operational boundaries; Terraform manages cloud infrastructure state; GitOps / Helm manages in-cluster application state without state file collision.
* **Disadvantages**: Requires managing two deployment layers.
* **Security Implications**: Strongest. Scoped IAM execution boundaries.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: High operational clarity for DevOps engineers.
* **Cost Implications**: Zero tool licensing cost.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Remote S3 state bucket setup.
* **Risks**: `RSK-DEL-001` (Uncoordinated releases between Terraform infrastructure updates and GitOps deployments).

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: CloudFormation | Option 2: AWS CDK | Option 3: Pure Terraform | Option 4: Hybrid (Terraform Infra + GitOps K8s) |
| :--- | :--- | :--- | :--- | :--- |
| **Declarative Clarity** | Moderate | Weak (Imperative) | **Strong** | **Strong** |
| **State Boundary Isolation** | Moderate | Weak | Moderate | **Strong (Decoupled)** |
| **Dry-Run Visibility (`AGENTS.md`)** | Weak | Moderate | **Strong (`plan`)** | **Strong (`plan`)** |
| **Open-Source Module Ecosystem**| Moderate | Moderate | **Strong** | **Strong** |
| **Reversibility** | Difficult | Reversible | Easily Reversible | **Easily Reversible** |

---

## Proposed Decision
**Option 4: Hybrid Model** (Modular Terraform / OpenTofu for AWS Infrastructure + Helm / Ansible / GitOps for Kubernetes Workloads).

---

## Rationale
Option 4 establishes clean operational boundaries that separate cloud infrastructure state management from application deployment logic, ensuring `terraform plan` provides transparent dry-run audits without state file pollution from ephemeral pod deployments (`AGENTS.md`).

---

## Consequences
* **Positive**: Clean separation of concerns; transparent `terraform plan` output; reusable modular architecture for Test and Prod accounts.
* **Negative**: Two operational tools to maintain (Terraform for AWS, Helm/GitOps for K8s).
* **New Operational Responsibilities**: Managing remote S3 backend state buckets and DynamoDB lock tables.
* **New Risks**: `RSK-DEL-001` (Terraform module dependency version drift).
* **Cost Consequences**: Zero software licensing fee.

---

## Validation Evidence
* Automated `terraform fmt`, `tflint`, and `terraform plan` execution check in Shared Services CI/CD pipeline.

## Acceptance Conditions
* Infrastructure Lead and DevOps Lead sign-off.

## Revisit Triggers
* Team standardizes on an enterprise internal developer portal requiring alternative IaC drivers.

## Implementation Implications
* Modular Terraform code authored in Phase 3 under `infrastructure/terraform/`.
