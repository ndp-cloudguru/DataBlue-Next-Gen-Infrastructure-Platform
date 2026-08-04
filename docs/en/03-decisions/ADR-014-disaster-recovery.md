# ADR-014 — Disaster Recovery Strategy

## Metadata
* **Status**: `Deferred`
* **Date**: 2026-08-03
* **Decision Owners**: Enterprise Architecture Board, Cloud Infrastructure Lead
* **Reviewers**: Customer Business Product Owners, Security Lead
* **Related Requirements**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-UNC-003` (Undefined RTO/RPO targets), `RSK-AVL-001` (Single-region AWS outage dependency)
* **Related Assumptions**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 13
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `NFR-003` mandates Disaster Recovery (DR) mechanisms to ensure business continuity during catastrophic events. **High Availability (Multi-AZ within 1 region) MUST NOT be confused with Disaster Recovery (Cross-Region failover)**. Multi-AZ protects against local hardware/zone failure, but leaves the platform vulnerable to a total AWS regional outage (`RSK-AVL-001`). Specific RTO and RPO metrics are currently unconfirmed (`OPEN-003`).

---

## Decision Drivers
1. **Target Recovery Time Objective (RTO)**: Maximum acceptable downtime duration during a regional outage (`NFR-003`).
2. **Target Recovery Point Objective (RPO)**: Maximum acceptable data loss window during a regional outage (`NFR-003`).
3. **AWS Infrastructure Cost Multiplier**: Evaluating how cross-region replication and standby compute impact monthly AWS cloud spend (`CST-001`).
4. **Operational Complexity**: Operational discipline required to execute automated or manual regional DNS failovers.

---

## Constraints
* RTO and RPO targets must be formally authorized by business product owners before selecting a DR topology.

---

## Options Considered

### Option 1: Multi-AZ High Availability Only (Single-Region Dependency, No DR)
* **Description**: Relying strictly on 3-AZ redundancy within the primary AWS region without cross-region replication.
* **Advantages**: Lowest cost (zero secondary region infrastructure or data transfer fees).
* **Disadvantages**: Entire platform goes offline during a total AWS regional failure; high risk of business disruption (`RSK-AVL-001`).
* **Security Implications**: Good within primary region.
* **Availability Implications**: Vulnerable to regional outage.
* **RTO / RPO Target**: RTO = Infinity (until AWS restores primary region); RPO = 0.
* **Operational Implications**: Minimal.
* **Cost Implications**: Lowest infrastructure cost.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Customer sign-off accepting regional outage risks.
* **Risks**: `RSK-AVL-001` (Complete business halt during AWS regional outage).

### Option 2: Backup and Restore (Cold Standby in Secondary Region)
* **Description**: Replicating database backups and Velero cluster manifests to a secondary AWS region S3 bucket. In a disaster, IaC scripts provision a new EKS cluster from scratch.
* **Advantages**: Minimal ongoing cost (only S3 cross-region data transfer fees).
* **Disadvantages**: High RTO (4 to 24 hours) to spin up EKS control plane, node groups, and restore database state.
* **Security Implications**: Excellent (Encrypted cross-region S3 copy).
* **Availability Implications**: Moderate.
* **RTO / RPO Target**: RTO = 4–24 hours; RPO < 1 hour.
* **Operational Implications**: High stress during emergency disaster declaration and IaC execution.
* **Cost Implications**: Very low ongoing cost (~$50-100/month for S3 cross-region storage).
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Modular Terraform IaC scripts (`ADR-015`).
* **Risks**: IaC script execution failure during emergency failover.

### Option 3: Pilot Light Strategy (Minimal Infrastructure in Secondary Region)
* **Description**: Provisioning a minimal secondary region footprint: cross-region read-replicas for databases, pre-provisioned VPC/subnets, and sleeping EKS control plane. EKS node pools scale up during failover.
* **Advantages**: Faster RTO (1 to 2 hours); near-zero data loss (RPO < 15 minutes).
* **Disadvantages**: Moderate ongoing monthly cost for secondary EKS control plane and database read-replicas.
* **Security Implications**: Excellent.
* **Availability Implications**: Strong regional resiliency.
* **RTO / RPO Target**: RTO = 1–2 hours; RPO < 15 minutes.
* **Operational Implications**: Requires maintaining secondary region IaC modules.
* **Cost Implications**: Moderate ongoing spend (~$300-800/month).
* **Vendor Lock-in**: Low-Moderate.
* **Migration Complexity**: Moderate.
* **Reversibility**: Reversible.
* **Preconditions**: Cross-region database replication support.
* **Risks**: Cross-region database synchronization lag.

### Option 4: Warm Standby / Active-Active Multi-Region
* **Description**: Hosting a fully provisioned, scaled-down active EKS cluster and real-time active-active / active-passive database cluster in the secondary AWS region with Cloudflare GTM / DNS health-check failover.
* **Advantages**: Near-zero RTO (< 5 minutes); near-zero RPO (< 1 minute).
* **Disadvantages**: Extremely expensive (doubles baseline infrastructure costs); high cross-region data transfer fees; extreme operational complexity for multi-region database state synchronization.
* **Security Implications**: Excellent.
* **Availability Implications**: Highest (99.999% platform availability).
* **RTO / RPO Target**: RTO < 5 minutes; RPO < 1 minute.
* **Operational Implications**: Heavy ongoing multi-region SRE operational burden.
* **Cost Implications**: Doubled monthly AWS spending (2x cost multiplier).
* **Vendor Lock-in**: High.
* **Migration Complexity**: Very High.
* **Reversibility**: Difficult.
* **Preconditions**: Multi-region database active-active capability.
* **Risks**: Split-brain database corruption and double billing.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Multi-AZ Only | Option 2: Backup & Restore | Option 3: Pilot Light | Option 4: Warm Standby |
| :--- | :--- | :--- | :--- | :--- |
| **RTO Capability** | None (Days) | 4–24 Hours | **1–2 Hours** | < 5 Minutes |
| **RPO Capability** | None | < 1 Hour | **< 15 Minutes** | < 1 Minute |
| **AWS Cost Multiplier** | **1.0x (Baseline)** | **1.05x** | 1.3x | 2.0x (Doubled) |
| **Operational Labor** | **Low** | Moderate | Moderate | Extremely Heavy |
| **Reversibility** | **Easily Reversible** | **Easily Reversible** | Reversible | Difficult |

---

## Proposed Decision
**Decision Deferred**.

---

## Rationale
Selecting a Disaster Recovery strategy without documented RTO and RPO targets is strictly prohibited under governance rules. 

Option 2 (Backup & Restore) or Option 3 (Pilot Light) are the leading technical candidates, but final selection is **deferred pending business system criticality classification and RTO/RPO sign-off from customer stakeholders** (`OPEN-003`).

---

## Validation Evidence Required Before Acceptance
1. Formal customer sign-off on RTO and RPO targets per business system (`OPEN-003`).
2. FinOps budget approval for secondary region infrastructure expenditure.

## Acceptance Conditions
* Business Product Owners, Enterprise Architecture Board, and FinOps Team written sign-off.

## Revisit Triggers
* Completion of Phase 1 Business Continuity Plan (BCP) review.

## Implementation Implications
* Platform IaC modules in Phase 3 are structured to be region-agnostic to support rapid multi-region deployment.
