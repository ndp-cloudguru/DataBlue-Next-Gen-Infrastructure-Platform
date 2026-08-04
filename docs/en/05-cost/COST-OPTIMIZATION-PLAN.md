# Cost Optimization Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **FinOps Cost Optimization & Governance Strategy** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

Governed by requirements [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), and [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md).

---

## 2. 12 FinOps Optimization Pillars

1. **Automated Non-Production Scale-Down**: Scheduled scaling down of Test EKS worker nodes outside business hours (reducing node count by 70% during night/weekends), saving ~35% on non-prod compute.
2. **Karpenter Just-in-Time Bin-Packing**: Eliminating pre-allocated EC2 Auto Scaling Group waste by dynamically matching node sizes to pod requests (`ADR-005`), saving 15-25% on raw compute.
3. **EC2 Spot Instance Tiering**: Utilizing Spot instances for 70% of Test environment compute workloads, yielding ~70% discount over On-Demand rates.
4. **Compute Savings Plans**: Applying 3-Year Compute Savings Plans to Production baseline EKS nodes, reducing baseline EC2 cost by 35-40%.
5. **Log Storage Lifecycle Archiving**: Streaming raw container logs via Fluent Bit to S3 Standard, transitioning to S3 Glacier Flexible Retrieval after 30 days (`ADR-012`), reducing log storage costs by 80%.
6. **Log Level Production Scoping**: Restricting microservice log levels in Production to `INFO` and `WARN` to eliminate debug log noise (`RSK-CST-002`).
7. **EBS Volume Optimization (`gp3`)**: Utilizing `gp3` storage volumes over legacy `gp2`, providing 20% lower cost per GB and decoupled baseline IOPS.
8. **Inter-AZ Traffic Reduction**: Enforcing Kubernetes Topology Spread Constraints and topology-aware routing (`topologyKeys`) to keep pod-to-pod communications within the same AZ, avoiding $0.01/GB cross-AZ network fees (`RSK-003`).
9. **Single NAT Gateway for Non-Production**: Provisioning 1 NAT Gateway for Test VPC instead of 3 Multi-AZ NAT Gateways, saving ~$65/month in fixed non-prod fees.
10. **AWS Secrets Manager ESO Caching**: External Secrets Operator (ESO) configured with 1-hour refresh interval to prevent excessive Secrets Manager API calls (`ADR-011`).
11. **Mandatory AWS Resource Tagging Policy**: Enforcing `CostCenter`, `Environment`, `BusinessSystem`, and `Owner` tags on 100% of provisioned AWS resources via AWS Organizations SCPs (`CST-002`).
12. **AWS Budgets & Cost Anomaly Alerts**: Configuring AWS Budgets with Slack/email notifications triggered at 85% of monthly budget forecast, and AWS Cost Anomaly Detection to alert on unexpected daily spend spikes exceeding 20%.
