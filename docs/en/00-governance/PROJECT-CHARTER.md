# Project Charter: DataBlue Next-Gen Infrastructure Platform

---

## 1. Business Objective

The primary objective of the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`) initiative is to design, model, and establish an enterprise-grade, highly available, dynamically scalable, and secure cloud-native infrastructure baseline on AWS.

The platform will provide a consolidated, automated container hosting environment for approximately 40 microservices spanning 5–6 core business systems, supported by enterprise middleware (MySQL, RabbitMQ, MongoDB, Redis, Nacos) and a unified CI/CD toolchain (GitLab, Jenkins, Ansible).

Key business goals include:
* **Business Agility**: Accelerate feature delivery across business systems through automated application deployment pipelines.
* **Operational Resilience**: Guarantee zero single points of failure (SPOF) in production with high availability (HA) and disaster recovery (DR) capabilities.
* **Cost Predictability**: Establish a transparent FinOps cost estimation and governance model to prevent AWS cost overruns.
* **Governance & Security**: Enforce strict environment isolation (Test vs. Production) and fine-grained access permission management.

---

## 2. Known Scope

* **Application Sizing Baseline**: Structuring requirements for ~40 microservices across 5-6 business systems.
* **Multi-Environment Architecture**: Complete isolation of Test and Production environments at both AWS account and cluster boundary levels.
* **Automated CI/CD Integration**: Defining deployment orchestration boundaries across GitLab, Jenkins, and Ansible.
* **Stateful Middleware Architecture**: Architectural evaluation of MySQL, RabbitMQ, MongoDB, Redis, and Nacos (AWS Managed Services vs. EKS Operators).
* **Multi-Tier Dynamic Scaling**: Designing Pod dynamic autoscaling (HPA), Node autoscaling (Karpenter/Cluster Autoscaler), and Database scaling mechanisms.
* **Observability & Security**: Comprehensive AWS-native and open-source monitoring, logging, tracing, IAM RBAC, and secret management.
* **Parametric Cost Estimation**: FinOps cost baseline modeling across compute, storage, data transfer, and middleware tiers.

---

## 3. Out of Scope

* **Application Code Refactoring**: Modifying business application source code or writing application-level business logic.
* **Immediate Infrastructure Provisioning**: Deploying live AWS VPCs, EKS clusters, or database instances during Phase 0 / Phase 1.
* **CI/CD Script Execution**: Executing active Jenkins/Ansible deployment pipelines during the architecture phase.
* **Self-Hosted Legacy Infrastructure Migration**: Physical server migration or database data migration execution.

---

## 4. Stakeholder Matrix

| Stakeholder Role | Responsibilities | Key Interest & Focus |
| :--- | :--- | :--- |
| **Enterprise Architecture Lead** | Overall technical governance, ADR sign-off, platform standards enforcement | System coherence, technical debt avoidance, security compliance |
| **Cloud Engineering / DevOps Lead** | Infrastructure design, IaC architecture, CI/CD pipeline integration | Operational maintainability, deployment automation, platform stability |
| **Business System Product Owners** | Defining business system SLAs, traffic expectations, deployment frequency | System uptime, deployment speed, minimal release disruption |
| **Information Security (SecOps)** | IAM permission enforcement, network isolation, compliance oversight | Least-privilege access, data encryption, audit trails, blast radius control |
| **Finance / FinOps Team** | Cost model review, budget cap approval, cloud spend tracking | Detailed AWS cost estimation, cost optimization, rightsizing policy |

---

## 5. Delivery Principles

1. **Architecture-First Governance**: Specifications, registers, and ADRs must be completed and approved before any IaC code is written.
2. **Reversible Decisions First**: Favor flexible, modular architectural abstractions while customer workload metrics remain incomplete.
3. **Strict Environment Segregation**: Test and Production environments must never share a single Kubernetes cluster unless explicitly documented and authorized via formal exception.
4. **Decoupled Resiliency Definitions**: Keep High Availability (HA), Backup, and Disaster Recovery (DR) distinctly separated in design and target SLAs.
5. **Evidence-Based Readiness**: No system or subsystem will be declared production-ready without empirical benchmark testing and written acceptance verification.

---

## 6. Key Success Indicators (KPIs)

* **Traceability Index**: 100% of architectural decisions and IaC modules traceable back to registered requirements (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`).
* **ADR Completeness**: Formal ADR coverage for all core trade-offs (EKS topology, Managed vs Self-Hosted middleware, CI/CD boundaries).
* **Environment Blast Radius**: 0 shared infrastructure dependencies between Test and Production environments.
* **Cost Predictability Variance**: AWS actual spend within ±15% of the parametric cost model baseline upon workload metric input.
* **Availability Compliance**: Production platform architecture validated to support multi-AZ High Availability (≥99.9% target SLA once workload is sized).
