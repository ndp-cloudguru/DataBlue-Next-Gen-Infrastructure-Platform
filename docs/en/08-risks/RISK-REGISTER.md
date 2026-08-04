# Risk Register: DataBlue Next-Gen Infrastructure Platform

---

## 1. Governance & Risk Taxonomy

This document contains the comprehensive **Risk Register** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

Risks are categorized into ten standardized domain taxonomies:
1. **Requirements Uncertainty** (`RSK-UNC`): Missing customer workload data, unconfirmed sizing, unstated targets.
2. **Architecture** (`RSK-ARC`): Multi-tool integration complexity, structural trade-offs.
3. **Availability** (`RSK-AVL`): Outages, multi-AZ vs DR confusion, regional failure exposure.
4. **Scalability** (`RSK-SCL`): Capacity bottlenecks, pod/node scaling limits, database connection limits.
5. **Security** (`RSK-SEC`): Access control, credential exposure, blast radius, excessive IAM permissions.
6. **Data** (`RSK-DAT`): Database protocol incompatibilities, unvalidated backup restorations.
7. **Operations** (`RSK-OPS`): Operational maintenance burden, lack of SLOs, production change control.
8. **Cost** (`RSK-CST`): Managed service cost spikes, uncontrolled autoscaling spending, observability log inflation.
9. **Vendor Dependency** (`RSK-VND`): Cloud lock-in vs open-source operational maintenance.
10. **Delivery** (`RSK-DEL`): IaC module complexity, schedule delays.

---

## 2. Comprehensive Risk Log

### 1. Requirements Uncertainty (`RSK-UNC`)

#### `RSK-UNC-001`: Missing CPU and Memory Workload Profiles
* **Risk Statement**: Absence of per-service CPU and memory metrics across ~40 microservices may lead to severe node mis-sizing.
* **Category**: Requirements Uncertainty
* **Cause**: Customer unable to provide container profiling metrics during Phase 0 (`OPEN-001`).
* **Consequence**: Over-provisioning AWS nodes (excessive spend) or under-provisioning nodes (application crash loops).
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)
* **Probability**: High | **Impact**: High | **Exposure**: High
* **Current Controls**: Initial provisional sizing default tiering (`ASM-006`).
* **Proposed Mitigation**: Implement Karpenter JIT autoscaling (`ADR-005`) and run container profiling tests in Test environment.
* **Contingency**: Deploy dynamic pod resource recommenders (Goldilocks / VPA) to adjust requests dynamically.
* **Owner**: FinOps Analyst / Cloud Architect | **Status**: Active | **Review Trigger**: Phase 1 benchmarking.

#### `RSK-UNC-002`: Missing Traffic RPS and Concurrency Information
* **Risk Statement**: Lack of peak Requests Per Second (RPS) and concurrent user connection metrics risks network and load balancer throttling.
* **Category**: Requirements Uncertainty
* **Cause**: Unstated customer traffic profiles.
* **Consequence**: Ingress ALB target group exhaustion and API HTTP 504 timeouts.
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Probability**: High | **Impact**: High | **Exposure**: High
* **Current Controls**: Provisionally configured ALB ingress controller scaling.
* **Proposed Mitigation**: Execute synthetic load testing during Phase 3 prototyping.
* **Contingency**: Enable AWS WAF rate-limiting and ALB pre-warming.
* **Owner**: Lead Infrastructure Architect | **Status**: Active | **Review Trigger**: Load test execution.

#### `RSK-UNC-003`: Missing Data Volume and Storage Growth Rate
* **Risk Statement**: Missing database storage baseline and monthly growth rates risks EBS volume exhaustion or budget overruns.
* **Category**: Requirements Uncertainty
* **Cause**: Unconfirmed customer database metrics.
* **Consequence**: Database write failures due to disk full errors.
* **Related Requirements**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md), [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Probability**: High | **Impact**: High | **Exposure**: High
* **Current Controls**: AWS EBS / RDS storage auto-expansion enabled.
* **Proposed Mitigation**: Solicit current legacy database disk usage from customer DBA.
* **Contingency**: Set CloudWatch storage utilization alerts at 75% capacity.
* **Owner**: Database Administrator | **Status**: Active | **Review Trigger**: Phase 1 data audit.

#### `RSK-UNC-004`: ~40 Services with Unknown Criticality and Dependencies
* **Risk Statement**: Treating all 40 microservices with equal priority risks misallocating high-availability and backup resources.
* **Category**: Requirements Uncertainty
* **Cause**: Missing business system tiering definitions (Tier 1 Mission-Critical vs Tier 3 Batch).
* **Consequence**: Over-provisioning non-critical background services while under-protecting core payment services.
* **Related Requirements**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-001`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Probability**: Medium | **Impact**: High | **Exposure**: High
* **Current Controls**: Universal multi-AZ default architecture.
* **Proposed Mitigation**: Customer Product Owners to establish Service Tier Matrix (Tier 1/2/3).
* **Contingency**: Prioritize Tier 1 microservices during DR failover sequences.
* **Owner**: Lead Application Architect | **Status**: Active | **Review Trigger**: Service Matrix sign-off.

---

### 2. Architecture & Delivery (`RSK-ARC`, `RSK-DEL`)

#### `RSK-ARC-001`: Multi-Tool CI/CD Integration Responsibility Drift
* **Risk Statement**: Overlapping responsibilities across GitLab, Jenkins, and Ansible may cause pipeline configuration drift and build failures.
* **Category**: Architecture
* **Cause**: Customer mandate for three concurrent CI/CD tools (`FUN-002`–`FUN-004`).
* **Consequence**: Uncoordinated releases, broken deployments, and duplicated build steps.
* **Related Requirements**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Probability**: Medium | **Impact**: Medium | **Exposure**: Medium
* **Current Controls**: Standardized Hybrid Overlay Model in [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md).
* **Proposed Mitigation**: Document explicit tool boundary contracts (GitLab: Trigger → Jenkins: Build → Ansible: Deploy).
* **Contingency**: Fallback to GitLab CI native pipelines if inter-tool Webhooks fail.
* **Owner**: DevOps Lead | **Status**: Active | **Review Trigger**: CI/CD dry-run test.

#### `RSK-ARC-002`: Stateful Workloads on Kubernetes Complexity
* **Risk Statement**: Hosting complex stateful applications (RabbitMQ, Nacos, MySQL) on EKS risks volume attach latencies during pod rescheduling.
* **Category**: Architecture
* **Cause**: Kubernetes pod reschedules require detached EBS volumes to re-attach across nodes.
* **Consequence**: Transient database or message broker downtime during node failovers.
* **Related Requirements**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md)
* **Probability**: Medium | **Impact**: High | **Exposure**: High
* **Current Controls**: AWS EBS CSI driver with `gp3` volumes.
* **Proposed Mitigation**: Prefer AWS Managed Services (RDS, ElastiCache) for critical stateful databases where viable.
* **Contingency**: Utilize multi-AZ application-level replication rather than relying on volume re-attaches.
* **Owner**: Data Architect / Infrastructure Lead | **Status**: Active | **Review Trigger**: ADR evaluations.

---

### 3. Security & Access (`RSK-SEC`)

#### `RSK-SEC-001`: CI/CD Pipeline Credential Exposure
* **Risk Statement**: Storing static AWS IAM access keys inside Jenkins build nodes or GitLab variables risks secret leakage.
* **Category**: Security
* **Cause**: Imperative deployment scripts accessing cloud APIs directly.
* **Consequence**: Unauthorized access to production AWS infrastructure.
* **Related Requirements**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Probability**: Medium | **Impact**: Critical | **Exposure**: High
* **Current Controls**: Mandatory AWS IRSA and OIDC federated authentication (`ADR-011`).
* **Proposed Mitigation**: Enforce zero static credentials policy across all CI/CD pipelines (`AGENTS.md`).
* **Contingency**: Automated Git repository secret scanning (git-leaks) in pre-commit hooks.
* **Owner**: Cloud Security Lead | **Status**: Active | **Review Trigger**: Security audit.

#### `RSK-SEC-002`: Excessive IAM and Kubernetes RBAC Permissions
* **Risk Statement**: Over-broad IAM policies (e.g. `AdministratorAccess`) assigned to developer roles or pod service accounts risks security compromise.
* **Category**: Security
* **Cause**: Expedient development access configuration.
* **Consequence**: Unauthorized resource deletion or cross-namespace privilege escalation.
* **Related Requirements**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Probability**: Medium | **Impact**: High | **Exposure**: High
* **Current Controls**: Least-privilege IAM policy generation rules in [`AGENTS.md`](../../AGENTS.md).
* **Proposed Mitigation**: Implement IAM Access Analyzer and automated RBAC audit scans.
* **Contingency**: Revoke wildcard IAM permissions immediately upon detection.
* **Owner**: Cloud Security Lead | **Status**: Active | **Review Trigger**: Security audit.

#### `RSK-SEC-003`: Cross-Environment Blast Radius Exposure
* **Risk Statement**: Compromise or misconfiguration in Test environment propagating into Production.
* **Category**: Security
* **Cause**: Co-locating Test and Prod in a single cluster or account.
* **Consequence**: Production downtime or customer data exfiltration caused by non-prod actions.
* **Related Requirements**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md)
* **Probability**: Low | **Impact**: Critical | **Exposure**: Medium
* **Current Controls**: Dedicated AWS Accounts and EKS Clusters for Test and Prod (`ADR-001`, `ADR-002`).
* **Proposed Mitigation**: Block all VPC peering between Test and Production VPCs.
* **Contingency**: Automated AWS Organizations SCP isolation of compromised account.
* **Owner**: Enterprise Security Lead | **Status**: Active | **Review Trigger**: Architecture sign-off.

---

### 4. Data & Resiliency (`RSK-DAT`, `RSK-AVL`)

#### `RSK-DAT-001`: Amazon DocumentDB and MongoDB Protocol Incompatibility
* **Risk Statement**: Microservices utilizing advanced MongoDB features failing at runtime if deployed on Amazon DocumentDB.
* **Category**: Data
* **Cause**: DocumentDB emulates MongoDB APIs but lacks full syntax equivalence (e.g. specific aggregation stages, index types).
* **Consequence**: Application database driver runtime errors and broken microservice queries.
* **Related Requirements**: [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Probability**: High | **Impact**: High | **Exposure**: High
* **Current Controls**: Deferring decision [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md) until compatibility audit is completed.
* **Proposed Mitigation**: Execute automated query compatibility scan against DocumentDB API support matrices.
* **Contingency**: Deploy genuine MongoDB Operator on EKS or MongoDB Atlas if DocumentDB incompatible.
* **Owner**: Lead Data Architect | **Status**: Active | **Review Trigger**: Code compatibility audit.

#### `RSK-DAT-002`: Backup Restoration Procedures Not Tested Regularly
* **Risk Statement**: Database and cluster backups becoming corrupted or un-restorable without team detection.
* **Category**: Data
* **Cause**: Backups configured without scheduled restoration dry-runs.
* **Consequence**: Total loss of business data during a ransomware or disaster recovery scenario.
* **Related Requirements**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **Probability**: Medium | **Impact**: Critical | **Exposure**: High
* **Current Controls**: Hybrid Backup Strategy defined in [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md).
* **Proposed Mitigation**: Schedule automated monthly restore verification tests into isolated Test subnets.
* **Contingency**: Maintain dual backup copies (AWS Backup snapshots + Velero S3 copies).
* **Owner**: Database Administrator / Operations Lead | **Status**: Active | **Review Trigger**: Monthly backup audit.

#### `RSK-AVL-001`: Multi-AZ High Availability Mistaken for Disaster Recovery
* **Risk Statement**: Assuming Multi-AZ deployment protects against total regional outages, leaving business continuity un-planned.
* **Category**: Availability
* **Cause**: Confusing local zone redundancy (HA) with cross-region business continuity (DR).
* **Consequence**: Platform completely unavailable during an AWS regional control plane or physical failure.
* **Related Requirements**: [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Probability**: Medium | **Impact**: Critical | **Exposure**: High
* **Current Controls**: Decoupled NFR definitions and explicit DR evaluation in [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md).
* **Proposed Mitigation**: Customer stakeholders sign off on formal RTO/RPO requirements and DR strategy.
* **Contingency**: Replicate encrypted database backups and IaC modules to a secondary AWS region.
* **Owner**: Enterprise Architect / Lead Cloud Architect | **Status**: Active | **Review Trigger**: BCP sign-off.

---

### 5. Cost & Operations (`RSK-CST`, `RSK-OPS`)

#### `RSK-CST-001`: Managed Service Cost Growth and Over-Provisioning
* **Risk Statement**: AWS Managed Service costs (RDS, ElastiCache, Secrets Manager) escalating rapidly beyond initial estimates.
* **Category**: Cost
* **Cause**: Provisioning high-tier managed instances prior to empirical workload profiling.
* **Consequence**: Monthly AWS cloud spending exceeding budget constraints (`BUS-004`).
* **Related Requirements**: [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Probability**: High | **Impact**: High | **Exposure**: High
* **Current Controls**: Parametric FinOps Cost Estimation Model setup (`CST-001`).
* **Proposed Mitigation**: Configure AWS Budgets and AWS Cost Anomaly Alerts with threshold notifications.
* **Contingency**: Rightsize instances or switch non-critical services to Spot / self-hosted options.
* **Owner**: FinOps Lead | **Status**: Active | **Review Trigger**: Monthly billing review.

#### `RSK-CST-002`: Uncontrolled Observability Log Ingestion Costs
* **Risk Statement**: Application debug logging or high-cardinality metric scraping causing massive CloudWatch / OpenSearch bill spikes.
* **Category**: Cost
* **Cause**: Microservices emitting un-filtered stdout debug logs in Production.
* **Consequence**: High monthly log ingestion and storage charges (`CST-001`).
* **Related Requirements**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **Probability**: High | **Impact**: Medium | **Exposure**: High
* **Current Controls**: Hybrid Observability architecture routing raw logs to S3 Glacier lifecycle archiving (`ADR-012`).
* **Proposed Mitigation**: Enforce log level filtering (`INFO`/`WARN` only in Production) at Fluent Bit daemonset.
* **Contingency**: Implement log sampling and rate-limiting at log collector layer.
* **Owner**: Lead Operations Engineer | **Status**: Active | **Review Trigger**: Weekly log volume check.

#### `RSK-OPS-001`: Heavy Operational Burden of Self-Hosted Middleware
* **Risk Statement**: Attempting to self-host MySQL, RabbitMQ, and MongoDB on EKS overloading platform SRE staff.
* **Category**: Operations
* **Cause**: Selecting open-source operators to save AWS managed service costs without adequate DBA staffing.
* **Consequence**: System downtime during database crashes due to lack of specialized DBA response.
* **Related Requirements**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Assumptions**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Probability**: High | **Impact**: High | **Exposure**: High
* **Current Controls**: Deferring stateful database decisions pending operational capability evaluation.
* **Proposed Mitigation**: Conduct formal Total Cost of Ownership (TCO) evaluation including SRE labor costs.
* **Contingency**: Transition complex databases to AWS Managed Services (RDS, ElastiCache).
* **Owner**: DevOps Lead / SRE Lead | **Status**: Active | **Review Trigger**: Phase 1 ADR sign-off.
