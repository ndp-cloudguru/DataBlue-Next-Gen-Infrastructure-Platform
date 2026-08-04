# Assumptions Register: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document records engineering and architectural assumptions made for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`) due to incomplete or missing customer workload metrics during Phase 0.

Each assumption is tracked, assigned an owner, and assigned a validation method to ensure it is systematically confirmed before IaC code generation in Phase 3.

---

## 2. Standardized Assumptions Log

### `ASM-001`: Microservice Container Readiness
* **Assumption**: All ~40 microservices across the 5–6 business systems are containerized (Docker/OCI compliant), stateless, and support 12-Factor application configuration via environment variables or Nacos.
* **Reason**: Customer specified a Kubernetes-based platform hosting 40 microservices.
* **Impact if False**: Stateful application components will require specialized persistent volume configurations, StatefulSets, or rewrite refactoring.
* **Validation Method**: Codebase container readiness audit and Dockerfile inspection across microservice repositories.
* **Owner**: Application Development Lead / Lead Architect
* **Status**: Open / Pending Validation

---

### `ASM-002`: AWS Account-Level Environment Segregation
* **Assumption**: Test and Production environments will be hosted in separate AWS accounts within an AWS Organization baseline (e.g. `DataBlue-Test-Account` and `DataBlue-Prod-Account`).
* **Reason**: Standard cloud security governance prohibits co-locating Test and Prod in a single EKS cluster via namespaces without explicit executive waiver.
* **Impact if False**: Co-locating Test/Prod in a single cluster creates severe blast-radius vulnerabilities, noisy-neighbor performance interference, and potential data security compliance breaches.
* **Validation Method**: Security Architecture sign-off and AWS Account structure confirmation.
* **Owner**: Cloud Security Lead / Enterprise Architect
* **Status**: Proposed Baseline / Pending Approval

---

### `ASM-003`: EKS Multi-AZ High Availability Topology
* **Assumption**: EKS worker nodes and stateful middleware will span at least 3 Availability Zones (AZs) within a single target AWS Region (e.g. `us-east-1` or `ap-southeast-1`).
* **Reason**: Multi-AZ topology is required to satisfy the High Availability (HA) requirement (`NFR-001`).
* **Impact if False**: Single-AZ or 2-AZ deployments carry higher risk of control plane / worker node downtime during AWS zone impairments.
* **Validation Method**: Regional AWS AZ quota verification and VPC subnet topology plan review.
* **Owner**: Infrastructure Lead Architect
* **Status**: Draft / Under Evaluation

---

### `ASM-004`: Middleware Architecture Strategy Evaluation
* **Assumption**: Both AWS Managed Services (RDS MySQL, ElastiCache Redis, MSK/DocumentDB) and Self-Hosted Middleware Operators on EKS will be evaluated via formal ADR before finalizing the stateful service architecture.
* **Reason**: Customer specified MySQL, RabbitMQ, MongoDB, Redis, and Nacos without indicating preference for AWS managed vs. self-hosted on K8s.
* **Impact if False**: Prematurely committing to self-hosted increases operational burden; committing exclusively to AWS managed services increases vendor lock-in and potential cloud costs.
* **Validation Method**: Phase 1 ADR trade-off evaluation matrix (`OPEN-002`).
* **Owner**: Data Architect / Cloud Infrastructure Lead
* **Status**: Open / Trade-off Pending

---

### `ASM-005`: CI/CD Pipeline Responsibility Separation
* **Assumption**: GitLab handles source code triggers; Jenkins orchestrates container builds, image scanning, and registry pushes to AWS ECR; Ansible executes target environment configuration management and application deployment commands.
* **Reason**: Customer specification includes GitLab, Jenkins, and Ansible concurrently.
* **Impact if False**: Pipeline confusion, duplicated build steps, configuration drift, and uncoordinated release deployments.
* **Validation Method**: CI/CD Workflow Architecture Specification document approval.
* **Owner**: DevOps Lead Engineer
* **Status**: Proposed / Pending Review

---

### `ASM-006`: Initial Default Resource Allocation Model
* **Assumption**: Until actual service metrics are provided, baseline microservice resource requests will be provisionally modeled as: `Small` (0.25 vCPU, 0.5 GB RAM), `Medium` (0.5 vCPU, 1.0 GB RAM), and `Large` (1.0 vCPU, 2.0 GB RAM) across a 50/35/15 ratio.
* **Reason**: Sizing data is currently unavailable from customer (`OPEN-001`).
* **Impact if False**: Cost estimation model will require recalculation once empirical CPU/RAM metrics are supplied.
* **Validation Method**: Benchmark profiling in Test environment during Phase 3.
* **Owner**: FinOps Analyst / Cloud Architect
* **Status**: Provisional / Sizing Placeholder

---

### `ASM-007`: Regional Data Transfer & Storage Retention
* **Assumption**: Log data retention is assumed to be 30 days in CloudWatch/OpenSearch with S3 lifecycle archive to Glacier; database backups are assumed to follow 7-day daily snapshot retention.
* **Reason**: Customer non-functional metrics currently omit specific compliance retention windows.
* **Impact if False**: Extended retention requirements (e.g. 365 days for PCI-DSS/HIPAA) will increase AWS storage costs significantly.
* **Validation Method**: Customer Legal & Compliance requirement sign-off.
* **Owner**: Compliance Lead / Operations Engineer
* **Status**: Open / Pending Confirmation
