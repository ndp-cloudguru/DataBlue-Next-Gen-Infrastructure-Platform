# ADR Candidates Register: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document records all **Architecture Decision Record (ADR) Candidates** identified during Stage 2 (Architecture Definition) of the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with Stage 2 governance rules:
* Decisions marked here are **provisional candidates under evaluation**.
* No ADR is finalized until Phase 1 trade-off scoring and formal stakeholder sign-off are complete.

---

## 2. ADR Candidates Log

| Candidate ID | Decision Title | Options Under Evaluation | Impacted Requirements | Architectural Viewpoint | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ADR-CAN-001` | **Environment Isolation Model** | **Option A**: Dedicated AWS Accounts & EKS Clusters for Test & Prod.<br>**Option B**: Single Multi-Tenant EKS Cluster with Namespace Isolation. | `BUS-003`, `SEC-002`, `NFR-001` | Physical & Deployment / Security | Proposed Baseline (Option A) |
| `ADR-CAN-002` | **Stateful Middleware Architecture Strategy** | **Option A**: AWS Managed Services (RDS, ElastiCache, MSK/DocDB).<br>**Option B**: Self-Hosted Middleware Operators on EKS (Bitnami/ECK/KubeBlocks). | `FUN-005`–`FUN-009`, `CST-001`, `OPS-001` | Logical / Operational / FinOps | Under Evaluation |
| `ADR-CAN-003` | **Kubernetes Node Autoscaler Selection** | **Option A**: Karpenter (Just-in-Time node provisioning).<br>**Option B**: Standard Kubernetes Cluster Autoscaler (Auto Scaling Groups). | `NFR-002`, `CST-001`, `OPS-001` | Operational / Scalability | Under Evaluation |
| `ADR-CAN-004` | **Ingress Controller Architecture** | **Option A**: AWS Load Balancer Controller + NGINX Ingress Controller.<br>**Option B**: AWS VPC Lattice / Gateway API. | `BUS-001`, `SEC-003`, `OPS-001` | Edge & Ingress / Network | Under Evaluation |
| `ADR-CAN-005` | **In-Cluster Service Mesh Requirement** | **Option A**: Istio / Linkerd Service Mesh for mTLS and traffic splitting.<br>**Option B**: Native AWS VPC CNI + Kubernetes NetworkPolicies. | `SEC-003`, `OPS-001`, `NFR-002` | Security / Logical / Performance | Under Evaluation |
| `ADR-CAN-006` | **Secrets Management & Injection Topology** | **Option A**: AWS Secrets Manager + External Secrets Operator (ESO).<br>**Option B**: HashiCorp Vault Cluster + Vault Agent Injector. | `SEC-001`, `FUN-002`–`FUN-004`, `OPS-001` | Security & IAM | Under Evaluation |
| `ADR-CAN-007` | **Disaster Recovery Failover Model** | **Option A**: Multi-Region Cold Backup & Infrastructure-as-Code Restore.<br>**Option B**: Cross-Region Pilot Light / Warm Standby Cluster. | `NFR-003`, `CST-001` | Resiliency / Operational / FinOps | Under Evaluation |
| `ADR-CAN-008` | **Perimeter Edge Security & CDN/WAF Selection** | **Option A**: Cloudflare Enterprise Edge (Cloudflare DNS, CDN, WAF & Global Traffic Manager GTM).<br>**Option B**: AWS Route 53 + AWS CloudFront + AWS WAF. | `SEC-002`, `SEC-003`, `NFR-001`, `NFR-003` | Edge & Security / Network / Resiliency | Proposed Baseline (Option A) |
