# ADR-004 — CI/CD Operating Model

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: DevOps Lead, Infrastructure Architect
* **Reviewers**: Enterprise Architecture Board, Security Team
* **Related Requirements**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-SEC-001` (CI/CD pipeline credential exposure), `RSK-ARC-001` (Multi-tool pipeline responsibility drift)
* **Related Assumptions**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 6
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Customer requirements specify the simultaneous integration of GitLab (`FUN-002`), Jenkins (`FUN-003`), and Ansible (`FUN-004`) for automated deployment (`BUS-002`). We must define an operating model that prevents duplicated pipeline steps, configuration drift, and security credential exposure.

---

## Decision Drivers
1. **Tooling Requirement Compliance**: Fulfilling customer directives for GitLab, Jenkins, and Ansible.
2. **Clear Operational Separation**: Mapping explicit boundaries so each tool handles a single responsibility domain.
3. **Pipeline Credential Security**: Restricting deployment credentials to secure, dedicated execution agents (`SEC-001`).
4. **GitOps & Configuration Drift Control**: Ensuring target environment state remains declarative and auditable (`BUS-002`).

---

## Constraints
* Must integrate GitLab, Jenkins, and Ansible as mandated by functional requirements.

---

## Options Considered

### Option 1: Pure GitLab CI/CD (Bypassing Jenkins & Ansible)
* **Description**: Utilizing GitLab CI/CD exclusively for source control, container building, testing, and deployment.
* **Advantages**: Highly streamlined single-vendor CI/CD pipeline; simple developer workflow.
* **Disadvantages**: Violates requirements `FUN-003` (Jenkins) and `FUN-004` (Ansible); ignores existing customer Jenkins/Ansible tooling investments.
* **Security Implications**: Good centralized secret management.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: Minimal operational tool sprawl.
* **Cost Implications**: Low tool maintenance cost.
* **Vendor Lock-in**: High (GitLab ecosystem lock-in).
* **Migration Complexity**: High (re-writing legacy Jenkins pipelines).
* **Reversibility**: Reversible.
* **Preconditions**: Customer waiver of Jenkins/Ansible requirements.
* **Risks**: Non-compliance with customer platform mandates.

### Option 2: Pure Jenkins CI/CD (Bypassing GitLab CI & Ansible)
* **Description**: Triggering builds directly from Webhooks in Jenkins, executing container builds, and running deployment scripts directly via Jenkins plugins.
* **Advantages**: Leverages existing Jenkins build script assets.
* **Disadvantages**: High risk of imperative script sprawl; bypasses Ansible configuration drift control (`FUN-004`); complex credential management inside Jenkins slaves.
* **Security Implications**: Weak. Storing cloud deployment keys directly on Jenkins build nodes.
* **Availability Implications**: Moderate.
* **Scalability Implications**: Moderate.
* **Operational Implications**: High pipeline script maintenance burden.
* **Cost Implications**: Moderate.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: High.
* **Reversibility**: Difficult.
* **Preconditions**: None.
* **Risks**: Pipeline configuration drift and credential exposure (`RSK-SEC-001`).

### Option 3: Hybrid Overlay Operating Model (GitLab → Jenkins → Ansible + GitOps)
* **Description**: Establishing a decoupled multi-tool pipeline architecture:
  1. **GitLab**: Source code version control, Merge Request triggers, and webhook dispatch (`FUN-002`).
  2. **Jenkins**: CI Build, unit testing, container vulnerability scanning, image packaging, and ECR pushing (`FUN-003`).
  3. **Ansible**: Infrastructure configuration management, environment drift remediation, and deployment execution (`FUN-004`).
  4. **ArgoCD / GitOps**: Declarative in-cluster state synchronization for Kubernetes manifests (`BUS-002`).
* **Advantages**: Satisfies 100% of customer toolchain requirements; establishes clear domain separation; eliminates credential exposure by scoping IAM permissions strictly to Ansible control nodes / ArgoCD service accounts.
* **Disadvantages**: Multi-tool operational overlay requires strict pipeline contract documentation (`RSK-ARC-001`).
* **Security Implications**: Strong. Strict least-privilege IAM role isolation across pipeline stages.
* **Availability Implications**: High. Isolated toolchain failure domains.
* **Scalability Implications**: High. Ephemeral Jenkins build agents.
* **Operational Implications**: Requires documented pipeline execution contracts.
* **Cost Implications**: Standard runner infrastructure costs.
* **Vendor Lock-in**: Low (Loose tool coupling).
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Standardized API contract between Jenkins and Ansible trigger endpoints.
* **Risks**: `RSK-ARC-001` (Inter-tool pipeline communication failures).

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Pure GitLab | Option 2: Pure Jenkins | Option 3: Hybrid Overlay (GitLab+Jenkins+Ansible) |
| :--- | :--- | :--- | :--- |
| **Requirement Compliance (`FUN-002..004`)** | Weak (Violates requirement) | Weak (Violates requirement) | **Strong (100% Compliant)** |
| **Credential Security** | Moderate | Weak | **Strong** |
| **Drift Control** | Moderate | Weak | **Strong** |
| **Operational Clarity** | High | Low | **Moderate-High** |
| **Reversibility** | Reversible | Difficult | **Easily Reversible** |

---

## Proposed Decision
**Option 3: Hybrid Overlay Operating Model** (GitLab for Source/Trigger → Jenkins for CI Build/Package → Ansible for Config/Deployment + GitOps).

---

## Rationale
Option 3 strictly satisfies functional requirements `FUN-002`, `FUN-003`, and `FUN-004` while establishing clear security boundaries that prevent Jenkins runners from storing long-lived cloud deployment credentials (`SEC-001`).

---

## Consequences
* **Positive**: 100% compliance with customer toolchain requirements; secure pipeline credentials; automated drift management via Ansible.
* **Negative**: Multiple tool integration points to maintain.
* **New Operational Responsibilities**: Maintaining API trigger contracts between GitLab Webhooks, Jenkins jobs, and Ansible execution hosts.
* **New Risks**: `RSK-ARC-001` (Pipeline interface contract drift).
* **Cost Consequences**: EC2 node costs for Jenkins master and Ansible control server.

---

## Validation Evidence
* Webhook trigger simulation and end-to-end pipeline test run in Shared Services account.

## Acceptance Conditions
* DevOps Lead and Security Team approval.

## Revisit Triggers
* Customer decision to consolidate CI/CD tooling onto a single SaaS platform.

## Implementation Implications
* Ansible playbooks and Jenkins pipelines authored in Phase 3.
