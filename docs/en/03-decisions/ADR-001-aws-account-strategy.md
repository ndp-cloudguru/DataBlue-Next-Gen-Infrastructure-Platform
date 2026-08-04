# ADR-001 — AWS Account Strategy

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Cloud Architect, Enterprise Security Lead
* **Reviewers**: Enterprise Architecture Board, DevOps Lead
* **Related Requirements**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-SEC-003` (Cross-environment blast radius), `RSK-CST-001` (Uncontrolled cost allocation)
* **Related Assumptions**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md) (AWS Account-level segregation)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 4
* **Supersedes**: None
* **Superseded By**: None

---

## Context
The DataBlue platform must host ~40 microservices across 5-6 business systems in distinct Test and Production environments (`BUS-001`, `BUS-003`). The organization requires strict security access controls, isolated blast radiuses, and clear cost attribution. We must decide how to structure AWS account boundaries.

---

## Decision Drivers
1. **Security & Blast Radius Isolation**: Preventing misconfiguration or compromise in Test from impacting Production (`SEC-002`).
2. **Cost Attribution & Billing Separation**: Accurate, friction-free cost accounting per environment (`CST-002`).
3. **AWS Service Limit Autonomy**: Avoiding API rate-limiting or quota contention between Test and Prod workloads.
4. **Compliance & Audit Alignment**: Centralized audit trails (CloudTrail) with least-privilege administrative access.

---

## Constraints
* Must operate natively within the AWS cloud ecosystem.
* Must support central governance via AWS Organizations.

---

## Options Considered

### Option 1: Single AWS Account (Co-located Test & Production)
* **Description**: All workloads hosted in one AWS Account using VPCs and IAM tags to separate environments.
* **Advantages**: Simple initial setup; lowest administrative account overhead.
* **Disadvantages**: Severe blast-radius risk; shared AWS API rate limits; complex IAM policies; risk of accidental production resource deletion.
* **Security Implications**: Weak. Accidental cross-environment permissions are common.
* **Availability Implications**: Low. Test load spikes can trigger AWS API throttling affecting Prod.
* **Scalability Implications**: Moderate. Shared account quotas (e.g. Elastic IPs, VPC limits).
* **Operational Implications**: High operational risk during administrative actions.
* **Cost Implications**: Difficult to isolate shared resource costs accurately.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: High if forced to split accounts later.
* **Reversibility**: Difficult to reverse once resources are provisioned.
* **Preconditions**: None.
* **Risks**: `RSK-SEC-003` (Severe security blast-radius vulnerability).

### Option 2: Two Separate Accounts (Dedicated Test Account & Prod Account)
* **Description**: Provisioning two distinct AWS accounts (one for Test, one for Production).
* **Advantages**: Strong environment isolation; clear billing boundaries between Test and Prod.
* **Disadvantages**: Lacks dedicated accounts for centralized security logging and shared CI/CD tools.
* **Security Implications**: Moderate-High. Good environment isolation, but security logs remain co-located.
* **Availability Implications**: High. Test issues cannot affect Production API limits.
* **Scalability Implications**: High. Independent AWS service quotas per environment.
* **Operational Implications**: Moderate management overhead.
* **Cost Implications**: Clear cost separation for runtime environments.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Moderate.
* **Reversibility**: Reversible with migration.
* **Preconditions**: AWS Organizations setup.
* **Risks**: Shared CI/CD runner access credentials spanning environments.

### Option 3: Multi-Account Landing Zone (AWS Organizations Control Tower)
* **Description**: Four dedicated AWS Accounts: Security/Logging, Shared Services (GitLab/Jenkins/ECR), Test Account, Production Account.
* **Advantages**: Maximum security isolation; centralized audit logging; dedicated shared services CI/CD pipeline boundary; independent billing.
* **Disadvantages**: Higher initial setup complexity; requires cross-account IAM role governance.
* **Security Implications**: Excellent. Zero shared IAM credentials between Test and Prod; centralized immutable S3 security logging.
* **Availability Implications**: Excellent. Complete independence of quotas and runtimes.
* **Scalability Implications**: Excellent. Scalable organizational unit (OU) model.
* **Operational Implications**: Requires AWS Control Tower / IAM Identity Center management capability.
* **Cost Implications**: Baseline AWS fixed costs (e.g. AWS Config, GuardDuty per account).
* **Vendor Lock-in**: Moderate (AWS Control Tower structure).
* **Migration Complexity**: Moderate.
* **Reversibility**: Easily reversible / extensible.
* **Preconditions**: AWS Organizations enabled.
* **Risks**: Cross-account network peering complexity.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Single Account | Option 2: Two Accounts | Option 3: Multi-Account Landing Zone |
| :--- | :--- | :--- | :--- |
| **Security & Blast Radius** | Weak | Moderate | **Strong** |
| **Availability Isolation** | Weak | Strong | **Strong** |
| **Cost Attribution** | Weak | Moderate | **Strong** |
| **Operational Complexity** | Low | Moderate | Moderate |
| **Reversibility** | Difficult | Reversible | **Easily Reversible** |

---

## Proposed Decision
**Option 3: Multi-Account Landing Zone** (Security/Logging, Shared Services, Test, Production).

---

## Rationale
Option 3 provides the strongest defense-in-depth security perimeter (`SEC-002`), enforces immutable audit trails (`OPS-002`), and satisfies FinOps cost attribution requirements (`CST-002`) without compromising availability.

---

## Consequences
* **Positive**: Complete blast-radius isolation; zero API limit contention; clear environment billing.
* **Negative**: Higher initial setup overhead for cross-account IAM roles.
* **New Operational Responsibilities**: AWS Control Tower governance and cross-account IAM role management.
* **New Risks**: Misconfigured cross-account IAM trust relationships.
* **Cost Consequences**: Nominal fixed monthly costs for multi-account Security services (GuardDuty, Config).

---

## Validation Evidence
* AWS Control Tower baseline configuration review and IAM cross-account role audit.

## Acceptance Conditions
* Enterprise Security Lead and Lead Cloud Architect written sign-off.

## Revisit Triggers
* AWS Organization restructuring or regulatory compliance scope change.

## Implementation Implications
* Multi-account structure will be provisioned in Phase 3 via modular IaC (Terraform).
