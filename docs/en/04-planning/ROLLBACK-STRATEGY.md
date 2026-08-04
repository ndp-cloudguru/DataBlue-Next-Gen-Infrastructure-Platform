# Rollback Strategy & Procedures: DataBlue Next-Gen Infrastructure Platform

---

## 1. Governance & Rollback Principles

This document specifies mandatory **Rollback Strategies and Procedures** across nine technical layers of the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with [`AGENTS.md`](../../AGENTS.md) and [`PROJECT-CHARTER.md`](../00-governance/PROJECT-CHARTER.md):
* **Every production change must have an automated or documented rollback procedure**.
* **No destructive action may be planned without backup and rollback validation**.

---

## 2. Layer-by-Layer Rollback Specifications

### 1. Infrastructure Change Rollback (Terraform / AWS Foundation)
* **Trigger**: `terraform apply` failure or unexpected resource destruction warning during execution (`WP-002`, `WP-004`).
* **Rollback Procedure**: Revert Git commit in Terraform repository; execute `terraform apply` targeting previous S3 state file version; restore deleted resource via AWS Backup snapshot if required.
* **Maximum Recovery Time**: < 30 minutes.

### 2. EKS Control Plane Upgrade Rollback
* **Trigger**: EKS control plane API server regression or plugin incompatibility post-upgrade (`ADR-003`).
* **Rollback Procedure**: AWS EKS control plane managed upgrades **cannot be downgraded to a previous minor version**. Mitigation requires deploying a parallel secondary EKS cluster on the previous minor version via Terraform, restoring cluster state via Velero, and switching DNS ingress.
* **Maximum Recovery Time**: < 2 hours.

### 3. Node Rollout & Autoscaling Rollback (Karpenter)
* **Trigger**: New EC2 AMI node pool causing pod crash loops or network CNI failures (`ADR-005`).
* **Rollback Procedure**: Update Karpenter `EC2NodeClass` CRD in Git to point to previous AMI ID; execute `karpenter.sh/do-not-disrupt: false`; Karpenter cordons and drains broken nodes, replacing them with stable AMI instances.
* **Maximum Recovery Time**: < 15 minutes.

### 4. Application Release Rollback (Microservices)
* **Trigger**: HTTP 5xx error rate > 0.01% or microservice pod crash loop post-deployment (`WP-017`).
* **Rollback Procedure**: Automated ArgoCD / Ansible rollback. ArgoCD reverts manifest image tag to previous stable Git commit SHA (`ecr.aws/microservice:previous-sha`); rolling update restores healthy pods (`CICD-DELIVERY-PLAN.md`).
* **Maximum Recovery Time**: < 5 minutes.

### 5. Database Migration Rollback (MySQL / MongoDB)
* **Trigger**: Schema migration script failure or application data corruption post-migration (`WP-011`).
* **Rollback Procedure**: Execute downward Liquibase / Flyway rollback SQL script. If data is corrupted, initiate Amazon RDS Point-in-Time Recovery (PITR) to restore database to exact second prior to migration execution (`ADR-013`).
* **Maximum Recovery Time**: < 30 minutes (PITR restore).

### 6. Middleware Upgrade Rollback (Redis / RabbitMQ / Nacos)
* **Trigger**: Stateful broker partition failure or Nacos Raft quorum instability post-upgrade (`WP-012`, `WP-013`).
* **Rollback Procedure**: Revert Helm release image tag via ArgoCD; restore volume state from Velero S3 snapshot if schema version was mutated.
* **Maximum Recovery Time**: < 20 minutes.

### 7. IAM & Security Policy Rollback
* **Trigger**: Over-restrictive IAM IRSA policy update blocking pod AWS API calls (`WP-003`).
* **Rollback Procedure**: Revert IAM policy HCL module in Terraform; execute `terraform apply`; EKS IRSA OIDC pod tokens refresh automatically.
* **Maximum Recovery Time**: < 10 minutes.

### 8. Network Architecture & Security Group Rollback
* **Trigger**: NetworkPolicy or Security Group misconfiguration dropping cross-AZ microservice traffic (`WP-004`).
* **Rollback Procedure**: Revert Security Group HCL module or NetworkPolicy YAML manifest in GitOps repository; ArgoCD syncs original default-deny ingress/egress rules.
* **Maximum Recovery Time**: < 5 minutes.

### 9. CI/CD Pipeline & Runner Rollback
* **Trigger**: Jenkins worker node or Ansible playbook deployment script error (`WP-010`).
* **Rollback Procedure**: Revert Jenkinsfile / Ansible playbook commit in Shared Services repository; pin pipeline runner to previous container image version.
* **Maximum Recovery Time**: < 10 minutes.
