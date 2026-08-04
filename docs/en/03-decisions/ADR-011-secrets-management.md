# ADR-011 — Secrets Management Topology

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Cloud Security Lead, DevOps Lead
* **Reviewers**: Enterprise Architecture Board
* **Related Requirements**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-SEC-001` (CI/CD credential exposure), `RSK-SEC-002` (Unencrypted secrets in etcd)
* **Related Assumptions**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 7, Section 8
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirement `SEC-001` mandates centralized access and permission management with zero static credentials stored in repositories or container images. We must select an enterprise secrets management architecture to inject database passwords, API tokens, and certificates into microservice pods across Test and Production environments.

---

## Decision Drivers
1. **Zero Static Credentials**: Eliminating hardcoded passwords in Git, CI/CD pipelines, or container images (`SEC-001`).
2. **KMS Envelope Encryption & Audit Trails**: Continuous secret rotation, AWS KMS envelope encryption, and CloudTrail audit logging.
3. **Operational Overhead & Kubernetes Integration**: Native synchronization into Kubernetes secrets without complex pod sidecar containers.

---

## Constraints
* Secrets injection must support EKS IAM Roles for Service Accounts (IRSA).

---

## Options Considered

### Option 1: Native Kubernetes Secrets (Base64 Encoded)
* **Description**: Storing application secrets directly as native Kubernetes Secret objects stored in etcd.
* **Advantages**: Built natively into Kubernetes; simple manifest syntax.
* **Disadvantages**: Base64 encoding is NOT encryption; secrets easily checked into Git repositories by accident; lacks automated secret rotation or centralized audit logging.
* **Security Implications**: Weak. Exposes plain-text secrets to anyone with namespace read access.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: High risk of credential leaks.
* **Cost Implications**: Zero additional cost.
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: None.
* **Risks**: `RSK-SEC-002` (Plain-text credential leakage in Git repositories or etcd backups).

### Option 2: AWS Secrets Manager + External Secrets Operator (ESO)
* **Description**: Centralizing master secrets in AWS Secrets Manager (encrypted via AWS KMS), synchronized automatically into ephemeral Kubernetes secrets inside EKS via the open-source External Secrets Operator (ESO).
* **Advantages**: Centralized AWS CloudTrail audit logging; automatic KMS key rotation; ESO uses IAM IRSA OIDC authentication (`SEC-001`); no sidecar latency overhead.
* **Disadvantages**: AWS Secrets Manager API pricing ($0.40/secret/month + $0.05 per 10k API calls).
* **Security Implications**: Excellent. KMS envelope encryption + strict IAM policy scoping per environment account.
* **Availability Implications**: High (AWS Secrets Manager 99.9% SLA).
* **Scalability Implications**: Excellent.
* **Operational Implications**: Low operational maintenance (offloads secret store maintenance to AWS).
* **Cost Implications**: Predictable low monthly spend (~$20-50/month total).
* **Vendor Lock-in**: Moderate (AWS Secrets Manager API).
* **Migration Complexity**: Low.
* **Reversibility**: Reversible.
* **Preconditions**: AWS KMS and EKS OIDC IRSA integration.
* **Risks**: API rate limiting if refresh intervals are misconfigured (mitigated by ESO caching).

### Option 3: HashiCorp Vault Cluster (Self-Hosted on EKS or Vault Dedicated)
* **Description**: Deploying a dedicated 3-node HashiCorp Vault cluster with Vault Agent Injector sidecars.
* **Advantages**: Multi-cloud portability; dynamic secret generation (ephemeral DB credentials).
* **Disadvantages**: High operational complexity; unseal key management; sidecar memory/CPU overhead on every pod; high licensing costs if enterprise features required.
* **Security Implications**: Excellent.
* **Availability Implications**: High if managed by dedicated Vault SRE team.
* **Scalability Implications**: High.
* **Operational Implications**: Heavy operational burden on platform team.
* **Cost Implications**: High (Self-hosted Vault compute + operational labor or Vault HCP license).
* **Vendor Lock-in**: Low (Cloud agnostic).
* **Migration Complexity**: High.
* **Reversibility**: Difficult.
* **Preconditions**: Dedicated Security/Vault engineering team.
* **Risks**: Unseal key loss or Vault storage backend corruption.

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Native K8s Secrets | Option 2: AWS Secrets Manager + ESO | Option 3: HashiCorp Vault |
| :--- | :--- | :--- | :--- |
| **Security & KMS Encryption** | Weak | **Strong** | **Strong** |
| **Audit Trails (`SEC-001`)** | Weak | **Strong (CloudTrail)** | Strong (Vault Audit) |
| **Operational Simplicity** | High | **High (Managed)** | Weak (High Overhead) |
| **Cost Efficiency** | High | **High** | Low |
| **Reversibility** | Easily Reversible | **Reversible** | Difficult |

---

## Proposed Decision
**Option 2: AWS Secrets Manager + External Secrets Operator (ESO)**.

---

## Rationale
Option 2 enforces least-privilege security (`SEC-001`), provides immutable AWS CloudTrail audit logs, and offloads secret store maintenance to AWS, avoiding the heavy operational burden of HashiCorp Vault while completely eliminating static plain-text credentials in Git repositories.

---

## Consequences
* **Positive**: 100% compliance with least-privilege IAM IRSA policies; automated secret rotation; zero static Git credentials.
* **Negative**: Nominal AWS Secrets Manager monthly API cost (~$20-50/month).
* **New Operational Responsibilities**: Managing ExternalSecrets custom resources and setting appropriate sync refresh intervals.
* **New Risks**: Secrets Manager API throttling if refresh interval is set under 1 minute.
* **Cost Consequences**: ~$0.40 per secret per month.

---

## Validation Evidence
* External Secrets Operator IAM IRSA authentication test and secret sync verification.

## Acceptance Conditions
* Cloud Security Lead and DevOps Lead sign-off.

## Revisit Triggers
* Multi-cloud migration mandate requiring cloud-agnostic secret stores.

## Implementation Implications
* ESO Helm chart and ExternalSecret CRD manifests deployed in Phase 3.
