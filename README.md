🌐 **Language / Ngôn ngữ / 语言**: [English](README.md) | [Tiếng Việt](README.vi.md) | [中文 (Chinese)](README.zh.md)

---

# DataBlue Next-Gen Infrastructure Platform Architecture

> **IMPORTANT PROJECT NOTICE**: Infrastructure implementation (Terraform modules, Kubernetes manifests, Helm charts, deployment scripts, or live AWS resource provisioning) **HAS NOT STARTED**. This repository currently contains Phase 0 Requirements Baseline, Stage 2 Architecture Specifications, Stage 3 Decisions & Risk Validation, Stage 4 Implementation Planning, Stage 5 Verification Planning artifacts, and Standalone Mermaid Diagrams under an Architecture-First Development methodology.

---

## 1. Project Overview

The **DataBlue Next-Gen Infrastructure Platform Project** (`datablue-nextgen-infra-platform`) is an enterprise initiative to reconstruct, normalize, validate, design, cost-model, plan, and establish verification frameworks for a production-grade, highly available, secure, and dynamically scalable cloud-native container platform on Amazon Web Services (AWS).

The target platform will host:
* **Business Systems**: Approximately 5–6 business system domains.
* **Microservices**: Approximately 40 distributed microservices across separate Test and Production environments.
* **Middleware & State Services**: Relational Database (MySQL), Distributed Message Queue (RabbitMQ), Document Database (MongoDB), In-Memory Cache (Redis), and Service Discovery/Configuration Center (Nacos).
* **CI/CD & Operational Toolchain**: GitLab for source control and pipeline triggers, Jenkins for build/test orchestration, and Ansible for configuration drift management and deployment automation.
* **Platform Capabilities**: Dynamic multi-tier scaling, high availability, disaster recovery, identity & access permission management (IAM/RBAC), comprehensive monitoring/observability, continuous FinOps cost control, and Stage 5 verification planning.

---

## 2. Current Status

* **Phase**: Stage 5 — Verification Planning & Trilingual Documentation Baseline
* **Status**: **ACTIVE / PLANNING COMPLETED**
* **Completed Milestones**:
  * Project Charter & Governance Rules (`PROJECT-CHARTER.md`, `AGENTS.md`, `AGENTS.vi.md`)
  * Requirement Reconstruction & Normalization (`REQUIREMENTS-REGISTER.md`)
  * Engineering Assumptions & Open Questions Registration (`ASSUMPTIONS-REGISTER.md`, `OPEN-QUESTIONS.md`)
  * Non-Functional Requirements & Acceptance Criteria Definitions (`NON-FUNCTIONAL-REQUIREMENTS.md`, `ACCEPTANCE-CRITERIA.md`)
  * Stage 2 Complete Architecture Specification (`ARCHITECTURE-SPECIFICATION.md`)
  * Stage 3 Master ADR Registry & 15 Individual ADR Documents (`ADR-001` through `ADR-015`)
  * Risk Register, Decision Dependencies, and Architecture Validation Package (`RISK-REGISTER.md`, `DECISION-DEPENDENCIES.md`, `ARCHITECTURE-VALIDATION.md`)
  * Stage 4 11-Phase Implementation Roadmap (`IMPLEMENTATION-ROADMAP.md`)
  * Work Breakdown Structure for 20 Work Packages (`WORK-BREAKDOWN-STRUCTURE.md`)
  * Acceptance Gates Framework `GATE-01` to `GATE-10` (`ACCEPTANCE-GATES.md`)
  * Parametric Cost Models & Scenarios 1 through 5 (`COST-MODEL.md`, `COST-SCENARIOS.md`)
  * Operating Model & Support Readiness Plan (`OPERATING-MODEL.md`, `SUPPORT-READINESS-PLAN.md`)
  * Stage 5 Verification Planning Package (11 artifacts in `docs/en/07-verification/`, `docs/vi/07-verification/`, and `docs/zh/07-verification/`)
  * **Trilingual Documentation Tree Structure** (`docs/en/`, `docs/vi/`, and `docs/zh/` with 58 markdown files each)
  * **Executive Proposal Package** (`final_proposal/` containing `PROPOSAL.vi.md`, `PROPOSAL.en.md`, and `PROPOSAL.zh.md`)
  * Standalone Architecture Diagrams Directory (`diagrams/src/`)
  * Multilingual AWS Cost Analysis Excel Reports & Python Generator (`cost_summary/`)

---

## 3. Project Scope

### In Scope (Stage 5 Completed)
1. **Requirements Reconstruction**: Normalization of functional, non-functional, security, operational, and financial requirements into traceable registers (`BUS-xxx`, `FUN-xxx`, `NFR-xxx`, `SEC-xxx`, `OPS-xxx`, `CST-xxx`).
2. **Architecture Governance**: Explicit operational rules for human-in-the-loop sign-offs, AI agent execution constraints, and phase transition gates.
3. **Decoupled Architecture Evaluation**: 17-section architecture specification covering System Context, Logical, Deployment, Network, Security, HA, Scalability, Observability, Backup, DR, and Cost Architecture.
4. **Architecture Decision Package**: 15 comprehensive ADRs evaluated against requirements, constraints, risks, operational capability, cost implications, and reversibility.
5. **Implementation & Cost Planning Package**: 19 controlled, traceable planning artifacts including WBS, Dependency Map, Bootstrap Plan, Migration Waves, Rollback Strategies, Scenario-Based Cost Models (Scenarios 1–5), and Operating Models.
6. **Verification Planning Package**: 11 Stage 5 artifacts including Requirement Traceability Matrix, Architecture Conformance Audit, Test Evidence Register, Security, Performance, HA, Backup/Restore, DR, Cost Validation, and Master Release Readiness Report.
7. **Trilingual Documentation**: Complete English (`docs/en/`), Vietnamese (`docs/vi/`), and Chinese (`docs/zh/`) documentation trees with 100% information parity (58 files each).
8. **Executive Proposal Package**: Unified executive proposal documents in `final_proposal/` (`PROPOSAL.vi.md`, `PROPOSAL.en.md`, `PROPOSAL.zh.md`).
9. **Standalone Mermaid Diagrams**: Dedicated `diagrams/src/` catalog containing raw `.mmd` diagrams for easy rendering and maintenance.

---

## 4. Repository Structure

```text
datablue-nextgen-infra-platform/
├── README.md                                    # English Master README (this file)
├── README.vi.md                                 # Vietnamese Master README (Bản tiếng Việt)
├── README.zh.md                                 # Chinese Master README (中文版)
├── AGENTS.md                                    # AI Coding Agent governance and stage-gated rules (English)
├── AGENTS.vi.md                                 # AI Coding Agent governance and stage-gated rules (Tiếng Việt)
├── final_proposal/                              # Executive Proposal Package (Bilingual & Trilingual Editions)
│   ├── README.md                                # Executive proposal package index and guide
│   ├── PROPOSAL.vi.md                           # Vietnamese Master Executive Proposal (Bản chính thức)
│   ├── PROPOSAL.en.md                           # English Master Executive Proposal
│   └── PROPOSAL.zh.md                           # Chinese Master Executive Proposal (中文版)
├── cost_summary/                                # Multilingual AWS Cost Analysis Excel Reports & Master Generator
│   ├── generate_cost_excel.py                   # Master Python OpenPyXL Excel Generator Script
│   ├── DataBlue_AWS_Cost_Analysis.xlsx          # Vietnamese Detailed Cost Analysis Workbook
│   ├── DataBlue_AWS_Cost_Analysis_EN.xlsx       # English Detailed Cost Analysis Workbook
│   └── DataBlue_AWS_Cost_Analysis_CN.xlsx       # Chinese Detailed Cost Analysis Workbook
├── diagrams/                                    # Standalone Architecture Mermaid Diagrams
│   ├── README.md                                # Diagrams inventory and rendering guide
│   ├── render.py                                # Automated Python diagram extractor & compiler
│   ├── src/                                     # Raw .mmd Mermaid source files
│   ├── svg/                                     # Rendered SVG vector graphics
│   └── png/                                     # Rendered PNG bitmap images
└── docs/
    ├── en/                                      # English Documentation Tree (58 Markdown Files)
    │   ├── 00-governance/
    │   ├── 01-requirements/
    │   ├── 02-architecture/
    │   ├── 03-decisions/
    │   ├── 04-planning/
    │   ├── 05-cost/
    │   ├── 06-operations/
    │   ├── 07-verification/
    │   ├── 08-risks/
    │   └── PROPOSAL.md
    ├── vi/                                      # Vietnamese Documentation Tree (58 Markdown Files)
    │   ├── 00-governance/
    │   ├── 01-requirements/
    │   ├── 02-architecture/
    │   ├── 03-decisions/
    │   ├── 04-planning/
    │   ├── 05-cost/
    │   ├── 06-operations/
    │   ├── 07-verification/
    │   ├── 08-risks/
    │   └── PROPOSAL.md
    └── zh/                                      # Chinese Documentation Tree (58 Markdown Files - 中文文档树)
        ├── 00-governance/
        ├── 01-requirements/
        ├── 02-architecture/
        ├── 03-decisions/
        ├── 04-planning/
        ├── 05-cost/
        ├── 06-operations/
        ├── 07-verification/
        ├── 08-risks/
        └── PROPOSAL.md
```

---

## 5. Requirement Identifiers & Conventions

All project artifacts strictly enforce standardized ID formatting to maintain 100% cross-traceability across specifications, ADRs, work packages, and verification test cases:

* **Business Requirements**: `BUS-001` through `BUS-004` (Executive Business Goals & Cost Targets)
* **Functional Requirements**: `FUN-001` through `FUN-009` (Core Microservices, CI/CD, DB, & Nacos Platform Capabilities)
* **Non-Functional Requirements**: `NFR-001` through `NFR-003` (99.9% High Availability, Sub-Minute Scaling, & DR RTO/RPO SLAs)
* **Security Requirements**: `SEC-001` through `SEC-003` (IRSA OIDC Identity, Isolated Subnets, KMS Encryption & Cloudflare WAF)
* **Operations & Observability**: `OPS-001` through `OPS-003` (OpenSearch Central Logging, Prometheus/Grafana APM, & FinOps Controls)
* **Cost Management Requirements**: `CST-001` through `CST-002` (Parametric Cost Scenarios 1–5 & Savings Plans)
* **Engineering Assumptions**: `ASM-001` through `ASM-005` (Unvalidated Workload Metrics & Capacity Assumptions)
* **Architecture Decision Records**: `ADR-001` through `ADR-015` (Master Technology Selection Packages)
* **Work Packages & Gates**: `WP-001` through `WP-020`, `GATE-01` through `GATE-10` (11-Phase Implementation Roadmap)
* **Test Evidence & Audit Artifacts**: `EVD-REQ-xxx`, `EVD-SEC-xxx`, `EVD-DR-xxx` (Stage 5 Verification Audit Package)

---

## 6. Executive Proposal & Governance Navigation

* **Executive Proposal Package**: [`final_proposal/`](final_proposal/)
* **Executive Proposal (Vietnamese - Primary)**: [`final_proposal/PROPOSAL.vi.md`](final_proposal/PROPOSAL.vi.md)
* **Executive Proposal (English)**: [`final_proposal/PROPOSAL.en.md`](final_proposal/PROPOSAL.en.md)
* **Executive Proposal (Chinese)**: [`final_proposal/PROPOSAL.zh.md`](final_proposal/PROPOSAL.zh.md)
* **English Documentation Index**: [`docs/en/`](docs/en/)
* **Vietnamese Documentation Index**: [`docs/vi/`](docs/vi/)
* **Chinese Documentation Index**: [`docs/zh/`](docs/zh/)
* **Standalone Diagrams Directory**: [`diagrams/`](diagrams/)
* **Cost Analysis Reports & Generator (Excel)**: [`cost_summary/`](cost_summary/)
* **Agent Governance Rules (English)**: [`AGENTS.md`](AGENTS.md)
* **Agent Governance Rules (Vietnamese)**: [`AGENTS.vi.md`](AGENTS.vi.md)
