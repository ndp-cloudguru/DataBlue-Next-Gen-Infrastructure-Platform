# DataBlue Next-Gen Infrastructure Platform — Executive Proposals Package

**Project Identifier**: `datablue-nextgen-infra-platform`  
**Governance Standard**: Architecture-First Governance Standard  
**Document Version**: 2.5 (Unified Cloud Platform SRE & DevSecOps RACI Proposal)  

---

## 📌 Executive Overview

Welcome to the **Final Proposal Package** for the **DataBlue Next-Gen Infrastructure Platform (NIP)**. 

This directory contains the production-ready executive proposal documents designed for stakeholder review, financial evaluation, and engineering execution. The platform is engineered to host **~40 microservices** across **5–6 business systems** on Amazon EKS (`v1.30+`) with strict environment isolation, automated CI/CD pipelines, and multi-account FinOps governance.

---

## 📂 Proposal Document Index

The master proposals are available in bilingual editions:

| Language Edition | Document File | Description & Target Audience |
| :--- | :--- | :--- |
| **🇻🇳 Tiếng Việt (Primary)** | [**`PROPOSAL.vi.md`**](PROPOSAL.vi.md) | Bản Đề xuất Technical & FinOps Master Architecture chính thức bằng Tiếng Việt. |
| **🇬🇧 English** | [**`PROPOSAL.en.md`**](PROPOSAL.en.md) | Official English Executive Proposal & Technical Specification Master Document. |

---

## 🏗️ Key Architecture & Governance Highlights

1. **Master 5-Layer Platform Architecture**:
   - **Layer 1 (Perimeter Edge)**: Cloudflare Enterprise Edge (DNS, CDN, WAF, GTM Geo-Routing).
   - **Layer 2 (Shared CI/CD & GitOps)**: GitLab, Jenkins CI with Trivy scanning, Ansible, ECR Registry, ArgoCD Operator.
   - **Layer 3 (EKS Compute Core)**: Amazon EKS `v1.30+` + Karpenter JIT sub-minute node autoscaling across Multi-AZ.
   - **Layer 4 (Isolated Databases)**: Amazon RDS MySQL Multi-AZ, ElastiCache Redis, Amazon MQ RabbitMQ, DocumentDB, Nacos 3-Node Raft.
   - **Layer 5 (Central Security & Observability)**: AWS Secrets Manager with ESO, KMS CMK, Fluent Bit, OpenSearch, S3 Glacier, Prometheus & Grafana.

2. **AWS Multi-Account Landing Zone Strategy (`ADR-001`, `ADR-002`)**:
   - Physical account isolation across `Prod Core Account (Account 1)`, `Prod Entry A (Account 2)`, `Prod Entry B (Account 3)`, `Dev/Test Isolated Account (Account 4)`, and `Shared Services Account (Account 5)`.

3. **Normalized 5 Enterprise Financial Scenarios**:
   - **Scenario 1 (Test Baseline)**: `~$1,600 – $2,400 / month` (2-AZ, 70% Spot, Karpenter, Dedicated CI/CD).
   - **Scenario 2 (Prod Baseline)**: `~$4,200 – $6,100 / month` (3-AZ, Savings Plans, RDS MySQL, OpenSearch).
   - **Scenario 3 (Prod Enhanced HA)**: `~$7,200 – $10,500 / month` (3-AZ, Aurora MySQL 3 Replicas, Redis Sharded 6-Node, OpenSearch 4-Node).
   - **Scenario 4 (Prod Cross-Region DR)**: `~$10,000 – $14,800 / month` (Primary `us-east-1` + Standby Pilot Light `us-west-2`, RTO < 4h, RPO < 15m).
   - **Scenario 5 (Enterprise Multi-Account Isolation)**: `~$12,000 – $18,500 / month` (5-Account AWS Landing Zone with Dual Entry Reverse Proxies, Transit Gateway Hub, and Zero-Internet Ingress Shared Services).

4. **Unified Operational Governance (Section 10)**:
   - Consolidated RACI matrix under a single **Cloud Platform SRE & DevSecOps Team**.

---

## 🗺️ Architectural Visualizations

Architecture diagrams and infographics referenced in the proposals are maintained in the repository:
- **Diagram Sources (Mermaid `.mmd`)**: [`../diagrams/src/`](../diagrams/src/)
- **Rendered High-Res Diagrams (PNG/SVG)**: [`../diagrams/png/`](../diagrams/png/) & [`../diagrams/svg/`](../diagrams/svg/)
- **High-Res Architecture Infographics**: [`../assets/`](../assets/) (e.g. [`../assets/scenario-5.png`](../assets/scenario-5.png))

---

## 🚀 Navigation & Next Steps

To review the full technical proposal, please open:
- [**Bản Tiếng Việt (PROPOSAL.vi.md)**](PROPOSAL.vi.md)
- [**English Version (PROPOSAL.en.md)**](PROPOSAL.en.md)
