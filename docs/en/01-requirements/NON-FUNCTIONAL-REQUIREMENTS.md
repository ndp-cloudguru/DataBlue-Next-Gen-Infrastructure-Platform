# Non-Functional Requirements: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the target quality attributes, operational constraints, and non-functional requirements for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

Where specific customer numeric performance, SLA, or sizing benchmarks are currently unavailable, the target is explicitly marked as **`TBD`**, accompanied by an explanation of the exact empirical evidence required to determine the final threshold.

---

## 2. Technical Quality Attributes

### 2.1 Availability
* **Multi-AZ Control Plane & Worker Topology**: EKS control plane (managed by AWS across 3 AZs) and worker nodes must maintain active multi-AZ distribution across at least 3 Availability Zones within the AWS target region.
* **Target Platform Uptime SLA**: **`TBD`**
  * *Evidence Needed*: Business SLA requirements per business system tier. Recommended baseline target is ≥99.9% for Production and ≥99.0% for Test.
* **Single Point of Failure (SPOF)**: Zero single points of failure permitted in the production compute, network, ingress (AWS ALB), or stateful middleware architecture.

---

### 2.2 Scalability
System scaling must be distinctly decoupled into three distinct tiers:

1. **Kubernetes Application Scaling (Pod Dynamic Scaling)**:
   * **Mechanism**: Horizontal Pod Autoscaler (HPA) based on CPU/Memory utilization, combined with KEDA (Kubernetes Event-driven Autoscaling) for RabbitMQ queue depth metrics.
   * **Target Response Window**: **`TBD`**
   * *Evidence Needed*: Microservice startup latency profiles and load testing burst metrics.

2. **Kubernetes Node Scaling (Cluster Infrastructure Scaling)**:
   * **Mechanism**: Karpenter or Cluster Autoscaler dynamically provisioning EC2 instances (mix of On-Demand and Spot instances for non-production workloads).
   * **Target Provisioning Time**: **`TBD`**
   * *Evidence Needed*: Node spin-up benchmark timings using pre-warmed AMI / Bottlerocket OS.

3. **Database & Middleware Scaling**:
   * **Mechanism**: Relational Read-Replica offloading (MySQL), Redis cluster sharding, MongoDB replica set scaling.
   * **Target Connection & IOPS Ceiling**: **`TBD`**
   * *Evidence Needed*: Database read-vs-write ratio analysis and connection pool profiling across microservices.

---

### 2.3 Performance
* **API Ingress Latency (P95 / P99)**: **`TBD`**
  * *Evidence Needed*: Customer performance baseline or SLA contract requirements (e.g. P95 latency < 200ms at AWS ALB boundary).
* **Throughput Capacity (Peak Requests Per Second - RPS)**: **`TBD`**
  * *Evidence Needed*: Business transaction volume metrics across the 5–6 business systems during peak business hours.
* **Storage IOPS & Latency**: Provisioned IOPS (gp3/io2) for database storage configured to maintain < 5ms read/write latency.

---

### 2.4 Security & Access Control
* **Least-Privilege Identity & Access Management (IAM & RBAC)**:
  * AWS IAM Roles for Service Accounts (IRSA) used exclusively for Pod-level AWS API access (zero hardcoded AWS credentials).
  * Kubernetes RBAC integrated with enterprise SSO/OIDC for operator cluster access.
* **Network Segregation & Perimeter Security**:
  * Test and Production workloads isolated into dedicated AWS Accounts.
  * Kubernetes NetworkPolicies enforcing default-deny ingress/egress rules between microservices.
  * AWS Security Groups enforcing strict port filtering at network boundaries.
* **Encryption Baseline**:
  * Data at Rest: Encrypted using customer-managed AWS KMS keys across EBS, RDS, ElastiCache, S3, and EKS secrets (etcd encryption).
  * Data in Transit: Mandatory TLS 1.3 encryption across all public API ingress endpoints and TLS 1.2+ for intra-cluster service-to-service communication.

---

### 2.5 Recoverability
Decoupled definitions for operational continuity:

* **High Availability (HA)**: Multi-AZ redundancy providing continuous operation during individual instance, pod, or Availability Zone failure. Target RTO = 0 (Seamless failover).
* **Point-in-Time Backup**: Automated daily snapshot lifecycle policies for MySQL, MongoDB, Redis, and etcd with cross-region S3 backup copy. Target Retention = 30 days (default, subject to compliance confirmation).
* **Disaster Recovery (DR)**:
  * **Target RTO (Recovery Time Objective)**: **`TBD`**
  * **Target RPO (Recovery Point Objective)**: **`TBD`**
  * *Evidence Needed*: Formal Business Continuity Plan (BCP) sign-off detailing acceptable data loss and recovery downtime during a total AWS region failure.

---

### 2.6 Observability & Server/Service Monitoring
* **Metrics & Server/Service Monitoring**: Continuous collection of node, container, pod, ingress, and middleware metrics via Prometheus/Grafana or AWS CloudWatch Container Insights.
* **Centralized Logging**: Application stdout/stderr, API ingress logs, and audit trails forwarded to Amazon OpenSearch / CloudWatch with automated lifecycle archiving.
* **Distributed Tracing**: OpenTelemetry / AWS X-Ray tracing integration for request flow visualization across the ~40 microservices.
* **Alerting SLA**: Automated PagerDuty / Slack alerts dispatched within < 2 minutes of critical metric threshold breaches (e.g. node failure, pod crash loop, storage > 85% full).

---

### 2.7 Maintainability & Infrastructure-as-Code (IaC)
* **Immutable Infrastructure**: 100% of AWS infrastructure provisioned via modular, version-controlled Terraform / OpenTofu modules. Zero manual AWS Console modifications permitted in Production.
* **Declarative GitOps Deployment**: EKS cluster workloads managed declaratively via GitOps pipelines.
* **Zero-Downtime Platform Upgrades**: EKS cluster and worker node OS updates executed via rolling blue/green node pool replacements without application outage.

---

### 2.8 Cost Control & FinOps Governance
* **Mandatory Resource Tagging Policy**: 100% of AWS resources tagged with `Environment` (`Test`/`Prod`), `BusinessSystem`, `CostCenter`, `ManagedBy` (`Terraform`), and `Owner`.
* **Cost Allocation Tracking**: Automated AWS Cost Explorer breakdown enabled per business system and environment.
* **Automated Non-Production Rightsizing**: Non-production (Test) environments scheduled for automated node scaling reduction during non-business hours (e.g. night/weekend scale down).
* **Cost Anomaly Detection**: AWS Cost Anomaly Detection configured to notify FinOps leads within 24 hours of unexpected spend spikes exceeding 20% over baseline.
