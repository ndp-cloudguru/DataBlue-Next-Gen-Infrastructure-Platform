# Scenario 5 Operational Runbook: Enterprise Multi-Account Isolation Architecture

**Project Identifier**: `datablue-nextgen-infra-platform`  
**Target Environment**: 5 AWS Accounts Landing Zone (`Prod Core`, `Prod Entry A`, `Prod Entry B`, `Dev/Test Isolated`, `Shared Services`)  
**Target Monthly Budget**: `$12,000 – $18,500 / month`  
**Governance Standard**: Architecture-First Governance Standard (`ADR-001`, `ADR-002`)

---

## 1. Architecture Diagram & Landing Zone Isolation Topology

Scenario 5 deploys a strict 5-account AWS Landing Zone architecture with dual Entry reverse proxies, AWS Transit Gateway Hub, and 100% isolation for Dev/Test:

```mermaid
flowchart TB
    subgraph GlobalEdge["Global Edge & Ingress Tier (Cloudflare Enterprise)"]
        Users["External End Users & Mobile Clients"] -->|HTTPS TLS 1.3| CF["Cloudflare Global DNS / CDN / WAF (GTM Load Balancing)"]
    end

    subgraph EntryA["Account 2 — Prod Entry A ($192/mo)"]
        CF -->|Prod Route A| IGW_A["AWS Internet Gateway (VPC 10.1.0.0/16)"]
        IGW_A --> ALB_A["Public ALB ($33/mo)"]
        ALB_A --> Proxy_A["ECS / Nginx Reverse Proxy ($60/mo) - Zero App Code / Zero DB"]
    end

    subgraph EntryB["Account 3 — Prod Entry B ($192/mo)"]
        CF -->|Prod Route B| IGW_B["AWS Internet Gateway (VPC 10.2.0.0/16)"]
        IGW_B --> ALB_B["Public ALB ($33/mo)"]
        ALB_B --> Proxy_B["ECS / Nginx Reverse Proxy ($60/mo) - Zero App Code / Zero DB"]
    end

    subgraph TGWHub["AWS Transit Gateway Hub — Network Routing ($250/mo)"]
        Proxy_A --> TGW["AWS Transit Gateway (TGW) - Connects Accounts 1, 2, 3 ONLY"]
        Proxy_B --> TGW
    end

    subgraph ProdCore["Account 1 — Prod Core Account ($5,200 - $8,500/mo)"]
        TGW -->|Private TGW Route| CoreALB["AWS ALB Ingress Controller"]
        CoreALB --> Ingress["EKS Ingress Tier"]
        Ingress --> Pods["40 Microservice Pods (EKS Cluster v1.30+)"]
        Pods --> Nacos["Nacos 3-Node Raft Cluster"]
        Pods --> Redis["Amazon ElastiCache Redis Multi-AZ"]
        Pods --> RabbitMQ["Amazon MQ RabbitMQ Quorum"]
        Pods --> DocDB["Amazon DocumentDB Cluster"]
        Pods --> RDS["Amazon RDS MySQL Multi-AZ"]
    end

    subgraph SharedServices["Account 5 — Shared Services Account ($800 - $1,200/mo)"]
        GitLab["GitLab Enterprise Registry"] -->|Webhook| Jenkins["Jenkins CI Master & Spot Agents"]
        Jenkins --> ECR["Amazon ECR Private Registry"]
        ArgoCD["ArgoCD Operator"] -->|GitOps Sync via PrivateLink| Pods
        ESO["External Secrets Operator"] -->|Secrets Sync via PrivateLink| Secrets["AWS Secrets Manager & KMS"]
        Secrets --> Pods
        PromGraf["Prometheus & Grafana"] -->|Federated Monitoring| Pods
    end

    subgraph DevTestAccount["Account 4 — Dev/Test Isolated Account ($1,600 - $2,400/mo) — NO TGW Attachment"]
        CF -->|Dev/Test Route| DevIGW["AWS Internet Gateway (Dev VPC 10.100.0.0/16)"]
        DevIGW --> DevALB["Dev/Test Public ALB"]
        DevALB --> DevProxy["Dev Reverse Proxy"]
        DevProxy --> DevEKS["Dev/Test EKS Cluster"]
        DevEKS --> DevPods["Dev/Test 40 Pods"]
        DevPods --> DevDB["Dev/Test Stateful Databases (RDS, Redis, MQ, DocDB)"]
    end

    %% Visual Color Styling
    style GlobalEdge fill:#E0F2FE,stroke:#0284C7,stroke-width:2px;
    style EntryA fill:#FEF3C7,stroke:#D97706,stroke-width:2px;
    style EntryB fill:#FEF3C7,stroke:#D97706,stroke-width:2px;
    style TGWHub fill:#F3E8FF,stroke:#9333EA,stroke-width:2px;
    style ProdCore fill:#DCFCE7,stroke:#16A34A,stroke-width:2px;
    style SharedServices fill:#FFEDD5,stroke:#EA580C,stroke-width:2px;
    style DevTestAccount fill:#FEE2E2,stroke:#DC2626,stroke-width:2px;
```

---

## 2. Multi-Account Terraform Provisioning Workflow

### 2.1 Multi-Account IAM Credentials Setup
Set up AWS CLI profiles for each of the 5 AWS Accounts using IAM Identity Center (SSO):
```bash
aws configure sso --profile datablue-prod-core
aws configure sso --profile datablue-prod-entry-a
aws configure sso --profile datablue-prod-entry-b
aws configure sso --profile datablue-dev-test
aws configure sso --profile datablue-shared-services
```

### 2.2 Terraform Multi-Provider Execution
```bash
# 1. Navigate to Scenario 5 directory
cd scenarios/scenario-5-enterprise-multi-account

# 2. Initialize Landing Zone backend
terraform init

# 3. Generate multi-account plan
terraform plan -out=tfplan-landing-zone

# 4. Apply Landing Zone configuration (GATE-07 CAB sign-off required)
terraform apply tfplan-landing-zone
```

---

## 3. Security Boundary & Connectivity Audit

### Rule 1: Dev/Test Isolation Audit (`Account 4`)
Verify that `Account 4 (Dev/Test)` has **ZERO** Transit Gateway attachments, **ZERO** VPC Peering connections, and **ZERO** access permissions to `Account 1 (Prod Core)`:
```bash
# Verify no TGW attachments exist in Account 4 Dev/Test
aws ec2 describe-transit-gateway-attachments --profile datablue-dev-test
# Expected output: [] (Empty)
```

### Rule 2: Shared Services Private Ingress Audit (`Account 5`)
Verify that `Account 5 (Shared Services)` has **ZERO** direct Public Internet Ingress routes. All access must be via AWS PrivateLink or internal VPC routing.

### Rule 3: Entry Proxy Reverse Proxy Health Check (`Account 2 & 3`)
Verify Nginx reverse proxy containers in Entry A and Entry B perform TLS termination and forwarding over AWS Transit Gateway Hub to `Account 1 Prod Core`:
```bash
curl -Iv https://entry-a.datablue.internal/healthz
curl -Iv https://entry-b.datablue.internal/healthz
```

---

## 4. Emergency Incident Runbook

### Emergency Isolation Protocol
In the event of an identified security breach in Entry A (`Account 2`):
1. Immediately detach Transit Gateway Attachment for `Account 2`:
   ```bash
   aws ec2 delete-transit-gateway-vpc-attachment --profile datablue-prod-core \
     --transit-gateway-attachment-id tgw-attach-entry-a-xxx
   ```
2. Cloudflare GTM automatically shifts 100% of ingress traffic to Entry B (`Account 3`).
3. Production Core (`Account 1`) remains 100% operational and protected.

---

## 5. Day-2 Multi-Account Troubleshooting Guide

### 5.1 Issue 1: Transit Gateway Packet Loss / Cross-Account Route Table Mismatch
* **Symptom**: Entry A (`Account 2`) reverse proxy receives HTTP 504 Gateway Timeout when forwarding traffic to Prod Core (`Account 1`).
* **Root Cause**: Transit Gateway Route Table missing static route entry for Prod Core VPC CIDR (`10.0.0.0/16`).
* **Troubleshooting & Remediation**:
  1. Inspect Transit Gateway Route Table in Prod Core Account (`Account 1`):
     ```bash
     aws ec2 describe-transit-gateway-route-tables --profile datablue-prod-core
     ```
  2. Add static route for `10.0.0.0/16` targeting Prod Core VPC Attachment.

### 5.2 Issue 2: Unauthorized Cross-Account Access Attempt Detected in GuardDuty
* **Symptom**: GuardDuty finding `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration` triggered in Account 4 (Dev/Test).
* **Root Cause**: Dev/Test IAM role attempted to call STS AssumeRole targeting Prod Core Account.
* **Troubleshooting & Remediation**:
  1. Verify Service Control Policies (SCP) in AWS Organizations: ensure SCP `DenyCrossAccountAssumeRoleDevToProd` is enforced on Organizational Unit `OU-DevTest`.
  2. Audit IAM Roles in Account 4 Dev/Test to revoke unapproved IAM trust policies.
