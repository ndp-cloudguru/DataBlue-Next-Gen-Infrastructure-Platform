# Operating Model: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the operational governance, RACI responsibility matrix, and domain boundaries for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

---

## 2. RACI Operational Responsibility Matrix

* **R**: Responsible (Executes the work)
* **A**: Accountable (Final decision maker)
* **C**: Consulted (Provides inputs)
* **I**: Informed (Kept updated)

| Operational Domain & Technical Scope | Cloud Platform SRE & DevSecOps Team | Database Administration Team (DBA) | Application Development Teams (App Dev) | Enterprise Operations & Support (Ops) |
| :--- | :--- | :--- | :--- | :--- |
| **AWS Account Landing Zone & VPC Subnets**| **A / R** | Informed | Informed | Informed |
| **EKS Control Plane & Worker Nodes** | **A / R** | Informed | Informed | Informed |
| **IAM IRSA, KMS Keys & Security Audit** | **A / R** | Informed | Informed | Informed |
| **CI/CD Pipeline Toolchain & ECR** | **A / R** | Informed | Consulted | Informed |
| **ArgoCD GitOps Releases & Manifests** | **A / R** | Informed | Consulted | Informed |
| **Database Operations (MySQL & DocumentDB)**| Consulted | **A / R** | Consulted | Informed |
| **Cache & Queue Operations (Redis & RabbitMQ)**| Consulted | **A / R** | Consulted | Informed |
| **Nacos Service Discovery Operations** | **A / R** | Consulted | Consulted | Informed |
| **Microservice Code & Pod Specs** | Consulted | Informed | **A / R** | Informed |
| **Prometheus, Grafana & APM Metrics** | **A / R** | Informed | Consulted | Consulted |
| **Centralized Logging (OpenSearch & S3)** | **A / R** | Informed | Informed | Informed |
| **Backup & Velero Snapshots** | **A / R** | Consulted | Informed | Informed |
| **Disaster Recovery Failover** | **A / R** | Consulted | Informed | Consulted |
| **24/7 Incident Response & Emergency Escalation**| **A / R** | Consulted | Consulted | **R** |
