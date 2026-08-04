# ADR-002 — Environment Isolation Model

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Cloud Architect, Security Engineer
* **Reviewers**: Enterprise Architecture Board
* **Related Requirements**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-SEC-003` (Shared cluster blast radius), `RSK-SCL-001` (Noisy neighbor contention)
* **Related Assumptions**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 4
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `BUS-003` mandates strict environment isolation between Test and Production environments. We must decide the boundary level for container runtime isolation (Kubernetes namespaces vs. physical cluster vs. AWS Account boundaries).

---

## Decision Drivers
1. **Blast Radius & Security Perimeter**: Eliminating the risk of non-production code or compromised pods accessing production data (`SEC-002`).
2. **Noisy Neighbor Performance Protection**: Preventing runaway CPU/memory usage or load spikes in Test from degrading Production workloads (`NFR-001`).
3. **Upgrade Risk Isolation**: Allowing EKS control plane and node OS upgrades to be thoroughly validated in Test without risking Production downtime.

---

## Constraints
* Test and Production must not share infrastructure unless explicitly authorized by formal security waiver.

---

## Options Considered

### Option 1: Separate Namespaces in a Single EKS Cluster
* **Description**: Hosting Test and Production workloads in one shared EKS cluster separated by K8s namespaces and NetworkPolicies.
* **Advantages**: Lowest AWS cluster control plane cost ($0.10/hr saving); simplified cluster administration.
* **Disadvantages**: Shared kernel/node blast radius; high risk of noisy-neighbor resource starvation; zero control-plane upgrade isolation; complex RBAC management.
* **Security Implications**: Weak. Container escape vulnerabilities expose production workloads.
* **Availability Implications**: Weak. Shared etcd and control plane failover impacts both environments.
* **Scalability Implications**: Moderate. Shared cluster API rate limits.
* **Operational Implications**: High risk during cluster maintenance.
* **Cost Implications**: Saves ~$73/month control plane fee.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: High to separate later.
* **Reversibility**: Difficult.
* **Preconditions**: None.
* **Risks**: `RSK-SEC-003` (Severe cross-environment blast radius).

### Option 2: Separate EKS Clusters in a Single AWS Account
* **Description**: Provisioning two distinct EKS clusters (Test Cluster, Prod Cluster) inside one AWS Account.
* **Advantages**: Physical Kubernetes control plane and worker node isolation.
* **Disadvantages**: Shared AWS IAM account boundary, shared VPC routing risks, shared cloud service limits.
* **Security Implications**: Moderate. Good K8s isolation, but shared AWS IAM credentials risk cross-access.
* **Availability Implications**: High. Isolated K8s control planes.
* **Scalability Implications**: High.
* **Operational Implications**: Moderate.
* **Cost Implications**: Adds $0.10/hr EKS control plane fee for Test cluster.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Moderate.
* **Reversibility**: Reversible.
* **Preconditions**: Single AWS Account setup.
* **Risks**: Accidental IAM credential reuse across environments.

### Option 3: Separate AWS Accounts and Separate EKS Clusters
* **Description**: Hosting Test in `DataBlue-Test-Account` with its own EKS Cluster, and Production in `DataBlue-Prod-Account` with its own EKS Cluster.
* **Advantages**: Absolute security and network blast-radius isolation; zero shared infrastructure; independent cluster upgrade lifecycles.
* **Disadvantages**: Requires managing multi-account IaC state files.
* **Security Implications**: Strongest. Zero cross-environment access paths.
* **Availability Implications**: Strongest. Complete failure domain isolation.
* **Scalability Implications**: Strongest. Completely independent AWS quotas.
* **Operational Implications**: Requires standardized IaC module automation.
* **Cost Implications**: Additional ~$73/month EKS control plane fee (negligible for enterprise platform).
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Multi-Account AWS Landing Zone (`ADR-001`).
* **Risks**: None identified for isolation.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Namespaces Only | Option 2: Clusters in 1 Account | Option 3: Separate Accounts & Clusters |
| :--- | :--- | :--- | :--- |
| **Security Blast Radius** | Weak | Moderate | **Strong** |
| **Noisy Neighbor Protection** | Weak | Strong | **Strong** |
| **Upgrade Safety** | Weak | Strong | **Strong** |
| **Operational Risk** | High | Moderate | **Low** |
| **Reversibility** | Difficult | Reversible | **Easily Reversible** |

---

## Proposed Decision
**Option 3: Separate AWS Accounts and Separate EKS Clusters**.

---

## Rationale
Option 3 strictly satisfies requirement `BUS-003` and `SEC-002` by guaranteeing complete physical, logical, and identity isolation between Test and Production.

---

## Consequences
* **Positive**: Zero risk of Test workloads affecting Production performance or security; safe cluster upgrade testing.
* **Negative**: Additional EKS control plane running cost ($0.10/hr for Test cluster).
* **New Operational Responsibilities**: Dual-cluster lifecycle management via GitOps/IaC.
* **New Risks**: None.
* **Cost Consequences**: ~$73/month additional control plane expense.

---

## Validation Evidence
* AWS Account boundary audit and EKS API endpoint isolation test.

## Acceptance Conditions
* Enterprise Security Lead approval.

## Revisit Triggers
* Explicit customer executive direction to reduce non-production AWS spend.

## Implementation Implications
* Separate EKS cluster modules defined in Terraform per AWS Account.
