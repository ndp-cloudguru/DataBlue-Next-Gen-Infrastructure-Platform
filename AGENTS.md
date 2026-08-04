# AI Agent Operating Rules & Guidelines: DataBlue Next-Gen Infrastructure Platform

> **Language / Ngôn ngữ**: [English](AGENTS.md) | [Tiếng Việt](AGENTS.vi.md)

---

## 1. Overview & Governance Philosophy / Tổng quan & Triết lý Quản trị

This document specifies mandatory operating rules, boundary conditions, and workflow constraints for all AI coding agents working on the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`) repository.

Tài liệu này quy định các quy tắc vận hành bắt buộc, điều kiện biên và quy trình làm việc cho tất cả các AI Agent hoạt động trong repository **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

All AI agents operating within this project must strictly adhere to **Architecture-First Governance** principles:

> **Architecture, Specifications, Traceability, and Human Sign-Off Must Precede Code Generation.**  
> *(Kiến trúc, Đặc tả, Khả năng Truy xuất Nguồn gốc và Sự Phê duyệt của Con người Bắt buộc Phải Có Trước khi Sinh Mã Nguồn).*

---

## 2. Core Architectural & Operational Directives / Chỉ thị Vận hành & Kiến trúc Cốt lõi

1. **Perimeter Edge Tier**: Always specify **Cloudflare Enterprise Edge (Cloudflare DNS, CDN, WAF & Global Traffic Manager GTM)** as the primary ingress security point preceding AWS Internet Gateways and Application Load Balancers (ALBs).
2. **Unified Operational RACI Team**: Cloud Platform SRE, DevOps Engineering, and Cloud Security are merged into a single combined role: **Cloud Platform SRE & DevSecOps Team**.
3. **Four Normalized Financial Scenarios**:
   - **Scenario 1 (Standard Non-Prod Test Baseline)**: `~$1,600 – $2,400 / month` (2-AZ, 70% Spot / 30% On-Demand, Karpenter Autoscaling, Dedicated CI/CD).
   - **Scenario 2 (Production Baseline)**: `~$4,200 – $6,100 / month` (3-AZ, 3-Yr Savings Plans, Managed RDS MySQL, 2-Node OpenSearch).
   - **Scenario 3 (Production High-Scale HA)**: `~$7,200 – $10,500 / month` (3-AZ, Transit Gateway, Amazon Aurora MySQL 3 Replicas, Redis Sharded Cluster 6-Node, 4-Node OpenSearch).
   - **Scenario 4 (Production Cross-Region DR)**: `~$10,000 – $14,800 / month` (Multi-AZ Primary `us-east-1` + Standby Pilot Light `us-west-2`, Cloudflare GTM Failover with RTO < 4h, RPO < 15m).
4. **Mermaid Diagrams Standard**: All system diagrams must be maintained in standalone `.mmd` files in `diagrams/src/` and compiled to SVG (`diagrams/svg/`) and PNG (`diagrams/png/`) using `python3 diagrams/render.py`. Implementation Roadmap (`Phase 0` to `Phase 10`) must use vertical orientation (`graph TD`).
5. **No Destructive Cloud Operations**: Agents are **STRICTLY PROHIBITED** from executing destructive cloud commands (e.g. `terraform destroy`, `aws ec2 terminate-instances`, `aws s3 rb`, `aws eks delete-cluster`) without explicit written human authorization.

---

## 3. Allowed vs. Prohibited Actions by Project Phase / Hành vi Được phép & Bị cấm theo Giai đoạn

| Project Phase / Giai đoạn | Allowed Actions / Hành vi Được phép | Prohibited Actions / Hành vi Bị cấm | Mandatory Approval Gate / Cổng Phê duyệt |
| :--- | :--- | :--- | :--- |
| **Phase 0: Specifications & Baseline** | • Reconstruct & normalize requirements<br>• Draft project specifications & registers<br>• Build cost estimation frameworks & diagrams | • Writing production Terraform/Helm modules<br>• Executing live AWS provisioning commands | Human sign-off on Phase 0 specification artifacts |
| **Phase 1: Architecture & ADRs** | • Author Architecture Decision Records (ADRs)<br>• Draw logical & network architecture diagrams<br>• Perform trade-off analysis | • Deploying live AWS resources<br>• Hardcoding sizing specs without empirical metrics | Human sign-off on published ADRs and architecture designs |
| **Phase 2: Detailed Design & Cost Modeling** | • Calculate parametric cost models (Scenarios 1–4)<br>• Define subnetting, IAM policies, and security groups | • Provisioning live cloud environments<br>• Applying IaC scripts directly to AWS | Human approval of cost models & detailed specs |
| **Phase 3: IaC & Manifest Prototyping** | • Writing modular Terraform / OpenTofu code<br>• Creating Helm charts & K8s manifests<br>• Running `terraform plan` / dry-runs in Sandbox | • Running `terraform apply` in Production<br>• Mutating state directly without GitOps | Human approval of `terraform plan` outputs |
| **Phase 4: Production & DR Handover** | • Running load tests & DR failover simulations<br>• Generating compliance reports & runbooks | • Destructive resource deletion<br>• Disabling security logging or audit trails | Explicit formal CAB & Human Lead approval |

---

## 4. Requirement Identifiers & Conventions / Quy ước & Mã Định danh

All project artifacts must strictly enforce standard ID formatting:
* **Business Requirements**: `BUS-001`, `BUS-002`, ...
* **Functional Requirements**: `FUN-001`, `FUN-002`, ...
* **Non-Functional Requirements**: `NFR-001`, `NFR-002`, ...
* **Security Requirements**: `SEC-001`, `SEC-002`, ...
* **Operations & Observability**: `OPS-001`, `OPS-002`, ...
* **Cost Management**: `CST-001`, `CST-002`, ...
* **Architecture Decision Records**: `ADR-001`, `ADR-002`, ...
* **Work Packages & Gates**: `WP-001`–`WP-020`, `GATE-01`–`GATE-10`.

---

## 5. Human-in-the-Loop Approval Protocol / Giao thức Phê duyệt của Con người

AI Agents must stop execution and request explicit human review whenever:
1. An ambiguity materially impacts AWS cloud spending or platform security boundaries.
2. An architecture decision requires a non-reversible commitment.
3. Any command or script execution could modify live AWS infrastructure state.
