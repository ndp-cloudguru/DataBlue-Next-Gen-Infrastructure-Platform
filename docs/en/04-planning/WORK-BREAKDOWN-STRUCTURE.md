# Work Breakdown Structure (WBS): DataBlue Next-Gen Infrastructure Platform

---

## 1. Governance & Structure

This document specifies the complete **Work Breakdown Structure (WBS)** for delivering the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

Every work package is traceable to Requirement IDs (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`), Architecture Decision Records (`ADR`), and Risk IDs (`RSK`).

---

## 2. Work Packages Catalog (WP-001 through WP-020)

### `WP-001`: Workload Evidence Collection & Profiling Framework
* **Description**: Establish profiling tools in non-prod environments to collect CPU, RAM, IOPS, and RPS metrics for the ~40 microservices (`OPEN-001`).
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Related Risks**: `RSK-UNC-001`, `RSK-UNC-002`, `RSK-DAT-001`
* **Dependencies**: None (Phase 0)
* **Inputs**: Legacy container images, developer codebases.
* **Deliverables**: Verified Workload Profiling Report & Resolved Middleware ADRs.
* **Responsible Role**: Lead Cloud Architect / SRE Lead
* **Validation**: Goldilocks / Prometheus resource metrics analysis.
* **Rollback Method**: Tear down temporary profiling sidecars.
* **Exit Criteria**: 100% of microservice sizing metrics logged and approved.
* **Status**: Ready for Execution

---

### `WP-002`: AWS Landing Zone & Multi-Account Structure Provisioning
* **Description**: Provision multi-account AWS Organization structure (`DataBlue-Test`, `DataBlue-Prod`, `Shared-Services`, `Security-Account`).
* **Related Requirements**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-015`](../03-decisions/ADR-015-infrastructure-as-code.md)
* **Related Risks**: `RSK-SEC-003`, `RSK-CST-001`
* **Dependencies**: `WP-001`, [`GATE-03`](ACCEPTANCE-GATES.md)
* **Inputs**: AWS Organization root credentials, Control Tower blueprint.
* **Deliverables**: Provisioned AWS Accounts with remote S3 Terraform state backends.
* **Responsible Role**: Infrastructure Lead Architect
* **Validation**: AWS Organizations API verification and account access audit.
* **Rollback Method**: Deprovision target organizational unit (OU) via Terraform.
* **Exit Criteria**: [`GATE-04`](ACCEPTANCE-GATES.md) sign-off.
* **Status**: Pending `GATE-03` Approval

---

### `WP-003`: IAM Identity Center, IRSA Roles & Security Baseline Setup
* **Description**: Configure centralized IAM Identity Center, OIDC provider for EKS, and IAM Roles for Service Accounts (IRSA).
* **Related Requirements**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Related Risks**: `RSK-SEC-001`, `RSK-SEC-002`
* **Dependencies**: `WP-002`
* **Inputs**: IAM policy specs, enterprise SSO directory endpoints.
* **Deliverables**: OIDC provider bindings, IRSA roles, AWS KMS customer-managed keys (CMKs).
* **Responsible Role**: Cloud Security Lead
* **Validation**: Automated IAM policy least-privilege analyzer scan.
* **Rollback Method**: Delete created IAM role policies via Terraform.
* **Exit Criteria**: Zero wildcard (`*`) IAM permissions detected.
* **Status**: Pending `WP-002`

---

### `WP-004`: VPC Network Architecture, Subnets & Routing Setup
* **Description**: Deploy 3-tier VPC network topology across 3 Availability Zones (Public, Private Application, Isolated Database subnets).
* **Related Requirements**: [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md)
* **Related Risks**: `RSK-SEC-003`, `RSK-CST-001`
* **Dependencies**: `WP-002`
* **Inputs**: Network CIDR allocation scheme.
* **Deliverables**: VPCs, subnets, NAT Gateways, route tables, and security groups.
* **Responsible Role**: Network Infrastructure Lead
* **Validation**: Automated route table reachability and subnet isolation tests.
* **Rollback Method**: `terraform destroy` on target VPC module.
* **Exit Criteria**: Zero route path between isolated database subnets and public internet.
* **Status**: Pending `WP-002`

---

### `WP-005`: Test EKS Control Plane & Worker Node Groups Construction
* **Description**: Deploy dedicated Test EKS cluster (`v1.30+`) in `DataBlue-Test-Account` across 3 AZs.
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md), [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md)
* **Related Risks**: `RSK-OPS-001`, `RSK-SCL-001`
* **Dependencies**: `WP-003`, `WP-004`
* **Inputs**: EKS cluster Terraform module specifications.
* **Deliverables**: Active EKS Test cluster with AWS VPC CNI, CoreDNS, and kube-proxy.
* **Responsible Role**: Cloud Infrastructure Architect
* **Validation**: `kubectl cluster-info` and node status health check.
* **Rollback Method**: `terraform destroy` on Test EKS module.
* **Exit Criteria**: [`GATE-05`](ACCEPTANCE-GATES.md) sign-off.
* **Status**: Pending `WP-004`

---

### `WP-006`: Test Environment Ingress, DNS & TLS Certificate Integration
* **Description**: Install AWS Load Balancer Controller, configure Cloudflare DNS & AWS Private Hosted Zones, and issue ACM TLS certificates.
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Related Risks**: `RSK-SEC-001`
* **Dependencies**: `WP-005`
* **Inputs**: Domain name specifications, ACM certificate requests.
* **Deliverables**: Functional ALB Ingress routing with valid TLS 1.3 encryption.
* **Responsible Role**: DevOps Engineer
* **Validation**: Synthetic HTTPS curl requests verifying SSL certificate chain.
* **Rollback Method**: Uninstall ALB Controller Helm chart.
* **Exit Criteria**: SSL Labs grade A rating for ingress endpoints.
* **Status**: Pending `WP-005`

---

### `WP-007`: GitOps Platform (ArgoCD) & Helm Release Management
* **Description**: Deploy ArgoCD GitOps controller into Test EKS cluster for declarative cluster manifest management.
* **Related Requirements**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md), [`ADR-015`](../03-decisions/ADR-015-infrastructure-as-code.md)
* **Related Risks**: `RSK-ARC-001`
* **Dependencies**: `WP-005`
* **Inputs**: ArgoCD Helm values file, GitOps application repository URIs.
* **Deliverables**: Operating ArgoCD instance syncing cluster manifests from Git.
* **Responsible Role**: DevOps Lead
* **Validation**: ArgoCD sync status audit across platform namespaces.
* **Rollback Method**: Delete ArgoCD custom resources.
* **Exit Criteria**: 100% of platform add-ons managed under GitOps control.
* **Status**: Pending `WP-005`

---

### `WP-008`: Observability Stack Deployment (Prometheus/Grafana + OpenSearch + S3)
* **Description**: Deploy Prometheus Operator, Grafana dashboards, Fluent Bit log forwarder, Amazon OpenSearch cluster, and S3 log lifecycle rules.
* **Related Requirements**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **Related Risks**: `RSK-CST-002`, `RSK-OPS-002`
* **Dependencies**: `WP-007`
* **Inputs**: Prometheus scrape configs, Grafana dashboard templates, OpenSearch domain specs.
* **Deliverables**: Operational monitoring dashboards and log search capability with S3 Glacier archiving.
* **Responsible Role**: Lead Operations Engineer
* **Validation**: Synthetic log/metric injection verifying end-to-end dashboard rendering.
* **Rollback Method**: Uninstall Observability Helm releases.
* **Exit Criteria**: Centralized log search operational with verified S3 archive export.
* **Status**: Pending `WP-007`

---

### `WP-009`: Platform Security & Secrets Management (ESO + AWS Secrets Manager)
* **Description**: Deploy External Secrets Operator (ESO) bound to AWS Secrets Manager via IAM IRSA roles.
* **Related Requirements**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Related Risks**: `RSK-SEC-001`, `RSK-SEC-002`
* **Dependencies**: `WP-003`, `WP-007`
* **Inputs**: AWS Secrets Manager secret specs, ESO ClusterSecretStore manifests.
* **Deliverables**: Automated secret synchronization from AWS Secrets Manager into K8s secrets.
* **Responsible Role**: Security Engineer
* **Validation**: Secret creation and sync audit test inside non-prod namespace.
* **Rollback Method**: Delete ESO controller custom resource.
* **Exit Criteria**: Zero plain-text static secrets checked into Git repositories.
* **Status**: Pending `WP-007`

---

### `WP-010`: CI/CD Pipeline Toolchain Integration (GitLab + Jenkins + Ansible)
* **Description**: Integrate GitLab source Webhooks, build Jenkins worker nodes, and write Ansible deployment automation playbooks.
* **Related Requirements**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Related Risks**: `RSK-ARC-001`, `RSK-SEC-001`
* **Dependencies**: `WP-007`, `WP-009`
* **Inputs**: Jenkinsfile templates, Ansible playbooks, ECR repository URIs.
* **Deliverables**: End-to-end automated deployment pipeline with ECR image scanning.
* **Responsible Role**: DevOps Lead
* **Validation**: Dry-run deployment pipeline execution test.
* **Rollback Method**: Revert Jenkins job definitions.
* **Exit Criteria**: Successful automated build and deployment dry-run.
* **Status**: Pending `WP-009`

---

### `WP-011`: Relational & Stateful Database Delivery (MySQL & MongoDB)
* **Description**: Provision high-availability MySQL and MongoDB database instances with 30-day PITR backup lifecycle policies.
* **Related Requirements**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md), [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **Related Risks**: `RSK-DAT-001`, `RSK-OPS-001`
* **Dependencies**: `WP-004`, `WP-009`, Phase 0 ADR Resolution
* **Inputs**: Database sizing metrics, KMS encryption keys.
* **Deliverables**: Multi-AZ database clusters with automated snapshot replication.
* **Responsible Role**: Database Administrator
* **Validation**: Multi-AZ failover and point-in-time recovery restore test.
* **Rollback Method**: Delete database instances via Terraform.
* **Exit Criteria**: Verified PITR backup restore test run.
* **Status**: Pending Phase 0 ADR Resolution

---

### `WP-012`: Cache & Messaging Delivery (Redis & RabbitMQ)
* **Description**: Provision high-availability Redis cache and RabbitMQ message broker clusters across 3 AZs.
* **Related Requirements**: [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md), [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md)
* **Related Risks**: `RSK-OPS-001`, `RSK-UNC-001`
* **Dependencies**: `WP-004`, `WP-009`, Phase 0 ADR Resolution
* **Inputs**: Cache RAM requirements, RabbitMQ quorum queue specifications.
* **Deliverables**: Multi-AZ Redis and RabbitMQ cluster endpoints.
* **Responsible Role**: Lead Infrastructure Architect
* **Validation**: Synthetic message publishing/subscribing and cache failover test.
* **Rollback Method**: Deprovision cache and broker clusters via Terraform / Helm.
* **Exit Criteria**: Sub-millisecond Redis latency and zero message loss failover.
* **Status**: Pending Phase 0 ADR Resolution

---

### `WP-013`: Nacos Service Discovery & Dynamic Configuration Cluster Delivery
* **Description**: Deploy multi-replica Nacos cluster on EKS in private subnets backed by the MySQL database tier (`FUN-009`).
* **Related Requirements**: [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md)
* **Related Risks**: `RSK-ARC-002`
* **Dependencies**: `WP-007`, `WP-011`
* **Inputs**: Nacos Helm chart, MySQL connection parameters.
* **Deliverables**: Operating 3-node Nacos cluster with dynamic config injection.
* **Responsible Role**: Lead Application Architect
* **Validation**: Service registration and dynamic configuration update test.
* **Rollback Method**: Delete Nacos StatefulSet.
* **Exit Criteria**: Verified dynamic configuration push to microservice pods.
* **Status**: Pending `WP-011`

---

### `WP-014`: Technical Pilot Microservice Onboarding & Load Testing
* **Description**: Onboard a 5-microservice pilot suite (API, worker, DB, cache, ingress) and execute synthetic load testing.
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md), [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **Related Risks**: `RSK-SCL-001`, `RSK-CST-001`
* **Dependencies**: `WP-010`, `WP-011`, `WP-012`, `WP-013`
* **Inputs**: Pilot application container images, Locust / k6 load test scripts.
* **Deliverables**: Technical Pilot Acceptance Benchmark Report.
* **Responsible Role**: SRE Lead / DevOps Lead
* **Validation**: Karpenter node autoscaling response time under 100% load burst.
* **Rollback Method**: Undeploy pilot microservices.
* **Exit Criteria**: [`GATE-06`](ACCEPTANCE-GATES.md) sign-off.
* **Status**: Pending `WP-013`

---

### `WP-015`: Production AWS Account & Production EKS Cluster Provisioning
* **Description**: Provision dedicated `DataBlue-Prod-Account` and Production EKS cluster following CAB approval.
* **Related Requirements**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md), [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md)
* **Related Risks**: `RSK-SEC-003`
* **Dependencies**: `WP-014`, [`GATE-07`](ACCEPTANCE-GATES.md) (CAB Approval)
* **Inputs**: Production Terraform modules, CAB authorization ticket.
* **Deliverables**: Isolated Production AWS Account and EKS Multi-AZ Cluster.
* **Responsible Role**: Lead Infrastructure Architect
* **Validation**: Production environment isolation audit.
* **Rollback Method**: `terraform destroy` on Production stack (requires CAB waiver).
* **Exit Criteria**: [`GATE-07`](ACCEPTANCE-GATES.md) sign-off.
* **Status**: Pending `GATE-07`

---

### `WP-016`: Production Security Hardening, Vault Lock & Backup Replication
* **Description**: Enable AWS Backup Vault Lock (ransomware protection) and cross-account S3 backup copy to Security Account.
* **Related Requirements**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **Related Risks**: `RSK-SEC-003`, `RSK-DAT-002`
* **Dependencies**: `WP-015`
* **Inputs**: Security Account S3 bucket policies, AWS Backup vault configuration.
* **Deliverables**: Immutable production backup vault with automated cross-account copy.
* **Responsible Role**: Cloud Security Lead
* **Validation**: Cross-account backup copy verification test.
* **Rollback Method**: Update S3 bucket lifecycle rule.
* **Exit Criteria**: Verified immutable backup copy in Security AWS Account.
* **Status**: Pending `WP-015`

---

### `WP-017`: Microservice Migration Waves Execution (Waves 1 through 5)
* **Description**: Onboard ~40 microservices into Production across 5 migration waves following wave entry/exit criteria.
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Related Risks**: `RSK-DEL-001`
* **Dependencies**: `WP-015`, `WP-016`
* **Inputs**: Microservice inventory, migration wave schedule.
* **Deliverables**: 100% of microservices deployed to Production environment.
* **Responsible Role**: DevOps Lead / Migration Lead
* **Validation**: End-to-end synthetic business transaction tests per wave.
* **Rollback Method**: Execute wave rollback playbooks (`ROLLBACK-STRATEGY.md`).
* **Exit Criteria**: [`GATE-09`](ACCEPTANCE-GATES.md) sign-off per wave.
* **Status**: Pending `WP-016`

---

### `WP-018`: Production Readiness, Chaos Testing & DR Failover Drills
* **Description**: Execute simulated node crashes, AZ outages, database failovers, and cross-region DR failover drills.
* **Related Requirements**: [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Related Risks**: `RSK-AVL-001`, `RSK-DAT-002`
* **Dependencies**: `WP-017`
* **Inputs**: Chaos Mesh test scenarios, DR failover runbooks.
* **Deliverables**: Production Readiness & Disaster Recovery Verification Report.
* **Responsible Role**: Lead Cloud Architect / SRE Lead
* **Validation**: RTO and RPO SLA compliance verification under simulated outage.
* **Rollback Method**: Restore primary region traffic routing.
* **Exit Criteria**: [`GATE-08`](ACCEPTANCE-GATES.md) sign-off.
* **Status**: Pending `WP-017`

---

### `WP-019`: FinOps Cost Optimization, Rightsizing & Budget Governance
* **Description**: Analyze production metric baselines, apply EC2/Compute Savings Plans, and enforce rightsizing.
* **Related Requirements**: [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related ADRs**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md)
* **Related Risks**: `RSK-CST-001`
* **Dependencies**: `WP-017`
* **Inputs**: AWS Cost Explorer metrics, 30-day node utilization baselines.
* **Deliverables**: FinOps Cost Optimization Report & Active Savings Plans Commitments.
* **Responsible Role**: FinOps Lead
* **Validation**: Actual AWS spend vs. cost model variance check (within ±15%).
* **Rollback Method**: N/A (FinOps policy adjustments).
* **Exit Criteria**: 100% of AWS resources tagged with valid CostCenter tags.
* **Status**: Pending `WP-017`

---

### `WP-020`: Operational Handover, Runbooks & Support Escalation Delivery
* **Description**: Deliver operational runbooks, conduct SRE training, and execute access handover to enterprise operations.
* **Related Requirements**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`AGENTS.md`](../../AGENTS.md)
* **Related ADRs**: All ADRs
* **Related Risks**: `RSK-OPS-001`, `RSK-OPS-002`
* **Dependencies**: `WP-018`, `WP-019`
* **Inputs**: Operations manuals, incident response runbooks.
* **Deliverables**: Signed Operational Handover Certificate and Support Matrix.
* **Responsible Role**: Lead Infrastructure Architect / Operations Lead
* **Validation**: Operational support simulation drill.
* **Rollback Method**: Extend hypercare project team support.
* **Exit Criteria**: [`GATE-10`](ACCEPTANCE-GATES.md) sign-off.
* **Status**: Pending `WP-019`
