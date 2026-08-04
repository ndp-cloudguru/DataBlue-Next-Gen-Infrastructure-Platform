# ADR-012 — Observability Architecture

## Metadata
* **Status**: `Proposed`
* **Date**: 2026-08-03
* **Decision Owners**: Lead Operations Engineer, Cloud Architect
* **Reviewers**: Enterprise Architecture Board, DevOps Lead
* **Related Requirements**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Related Risks**: `RSK-CST-002` (Uncontrolled observability log storage costs), `RSK-OPS-002` (Lack of service metric dashboards)
* **Related Assumptions**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Related Architecture Documents**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Section 11
* **Supersedes**: None
* **Superseded By**: None

---

## Context
Requirements `OPS-001` and `OPS-002` mandate comprehensive server and service monitoring, centralized log aggregation, and metric visualization across ~40 microservices, Kubernetes nodes, and middleware components. We must select the observability stack architecture while controlling AWS log storage costs (`CST-001`).

---

## Decision Drivers
1. **Unified Metric & Log Visibility**: Single-pane-of-glass dashboards for container metrics, node CPU/RAM, and application logs (`OPS-001`).
2. **Kubernetes & Cloud Native Alignment**: Prometheus metrics scraping compatibility across microservices and Nacos (`OPS-001`).
3. **Log Retention Cost Governance**: Controlling high ingestion and long-term storage costs for CloudWatch logs (`CST-001`, `OPS-002`).

---

## Constraints
* Must support centralized monitoring for Test and Production environments.

---

## Options Considered

### Option 1: Self-Hosted OSS Stack (Prometheus + Grafana + Loki on EKS)
* **Description**: Deploying Prometheus Operator, Grafana, and Loki log aggregator inside EKS using EBS persistent volumes.
* **Advantages**: Total open-source flexibility; zero AWS per-metric ingestion charges; rich Grafana dashboard ecosystem.
* **Disadvantages**: High worker node RAM and EBS storage consumption; team must manage Prometheus TSDB storage retention and Loki index scaling.
* **Security Implications**: Good. RBAC and network policies enforced.
* **Availability Implications**: Moderate. Storage node failures can cause temporary metric gaps.
* **Scalability Implications**: Requires manual TSDB storage tuning.
* **Operational Implications**: SRE team must manage observability cluster infrastructure.
* **Cost Implications**: Low AWS service fees, but higher node compute/storage consumption.
* **Vendor Lock-in**: Very Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: EKS storage capacity.
* **Risks**: Prometheus TSDB memory crash loop during metric cardinality explosions.

### Option 2: AWS Managed Service for Prometheus (AMP) + Managed Grafana (AMG)
* **Description**: Utilizing AWS fully managed Prometheus metric ingestion and AWS Managed Grafana workspace.
* **Advantages**: Zero server management; infinite metric storage scaling; 99.9% uptime SLA.
* **Disadvantages**: Ingestion pricing scales linearly with metric samples ($0.90 per million samples); high monthly cost for ~40 microservices with high metric cardinality.
* **Security Implications**: Excellent. Native AWS IAM SSO integration.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: Minimal operational burden.
* **Cost Implications**: High monthly AWS spend for high-cardinality metrics (`RSK-CST-002`).
* **Vendor Lock-in**: Moderate.
* **Migration Complexity**: Low.
* **Reversibility**: Reversible.
* **Preconditions**: AWS SSO / IAM Identity Center.
* **Risks**: `RSK-CST-002` (Unexpected monthly AWS bill spikes from high-cardinality metrics).

### Option 3: Pure AWS CloudWatch-Centric Solution
* **Description**: Utilizing CloudWatch Container Insights for metrics and CloudWatch Logs for all application logs.
* **Advantages**: Built-in AWS integration; zero helm chart deployments required.
* **Disadvantages**: Proprietary CloudWatch log query syntax; expensive log ingestion ($0.50/GB) and metric data pricing; poor developer dashboard flexibility compared to Grafana.
* **Security Implications**: Excellent.
* **Availability Implications**: High.
* **Scalability Implications**: High.
* **Operational Implications**: Minimal management.
* **Cost Implications**: Very high monthly ingestion fees.
* **Vendor Lock-in**: High (AWS CloudWatch proprietary format).
* **Migration Complexity**: High.
* **Reversibility**: Difficult.
* **Preconditions**: None.
* **Risks**: Extreme cost escalation for high log volumes.

### Option 4: Hybrid Architecture (Prometheus/Grafana + Fluent Bit to OpenSearch & S3)
* **Description**: A balanced hybrid architecture:
  1. **Prometheus Operator + Grafana on EKS**: High-speed, local metric scraping and visualization for operational dashboards (`OPS-001`).
  2. **Fluent Bit DaemonSet**: Lightweight log forwarder installed on all nodes.
  3. **Amazon OpenSearch Service**: Real-time log search and indexing for 7-14 days (`OPS-002`).
  4. **Amazon S3 Lifecycle Archiving**: Automated export of raw logs to S3 Standard / Glacier for long-term compliance retention at minimal cost (`CST-001`).
* **Advantages**: Delivers superior Grafana dashboard flexibility; controls log costs by archiving to S3; offloads log indexing from EKS node RAM to OpenSearch.
* **Disadvantages**: Requires configuring Fluent Bit routing rules and S3 lifecycle policies.
* **Security Implications**: Excellent. OpenSearch VPC isolation, KMS encryption.
* **Availability Implications**: High. Isolated logging failure domains.
* **Scalability Implications**: High. OpenSearch cluster auto-scaling.
* **Operational Implications**: Moderate management of Fluent Bit config maps.
* **Cost Implications**: Highly cost-effective (S3 lifecycle saves 80% on long-term log storage).
* **Vendor Lock-in**: Low.
* **Migration Complexity**: Low.
* **Reversibility**: Easily Reversible.
* **Preconditions**: Amazon OpenSearch cluster setup.
* **Risks**: `RSK-CST-002` (Unfiltered debug logging causing OpenSearch cluster storage exhaustion).

---

## Comparative Evaluation

| Evaluation Criteria | Option 1: Pure OSS | Option 2: AWS AMP/AMG | Option 3: CloudWatch | Option 4: Hybrid Solution |
| :--- | :--- | :--- | :--- | :--- |
| **Metric Flexibility (`OPS-001`)** | **Strong** | **Strong** | Weak | **Strong** |
| **Log Cost Control (`CST-001`)** | Moderate | Moderate | Weak | **Strong (S3 Lifecycle)** |
| **Operational Labor** | Heavy | **Minimal** | **Minimal** | Moderate |
| **Vendor Independence** | **Very High** | Moderate | Low | **High** |
| **Reversibility** | **Easily Reversible** | Reversible | Difficult | **Easily Reversible** |

---

## Proposed Decision
**Option 4: Hybrid Architecture** (Prometheus/Grafana on EKS + Fluent Bit to Amazon OpenSearch & S3).

---

## Rationale
Option 4 delivers the industry-standard Prometheus/Grafana dashboard experience (`OPS-001`), provides real-time log search via OpenSearch (`OPS-002`), and strictly controls FinOps costs by leveraging S3 Glacier lifecycle rules for long-term log archives (`CST-001`).

---

## Consequences
* **Positive**: 100% requirements compliance; sub-second metric dashboards; 80% cost savings on long-term log storage via S3 Glacier.
* **Negative**: Requires maintaining Fluent Bit DaemonSet configurations.
* **New Operational Responsibilities**: Managing OpenSearch cluster index rotation and S3 lifecycle policies.
* **New Risks**: `RSK-CST-002` (Log volume spikes if application debug logging is left enabled in Prod).
* **Cost Consequences**: Predictable OpenSearch instance pricing + low S3 storage costs.

---

## Validation Evidence
* Fluent Bit log forwarding benchmark and S3 log lifecycle export verification.

## Acceptance Conditions
* Operations Lead and FinOps Team sign-off.

## Revisit Triggers
* Log ingestion volume exceeding 500 GB/day.

## Implementation Implications
* Prometheus Operator and Fluent Bit Helm charts deployed in Phase 3.
