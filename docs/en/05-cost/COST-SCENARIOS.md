# Scenario-Based Cost Models: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document presents scenario-based financial projections for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirement `BUS-004` and governance rules:
* Cost estimates are **scenario-based projections**, not single guaranteed commitments.
* Figures serve as planning baselines until empirical workload profiling (`Phase 0`) is completed.

---

## 2. Four Enterprise Financial Cost Scenarios

```mermaid
graph TD
    Scen1["SCENARIO 1: Standard Test Environment (RECOMMENDED NON-PROD)<br/>~$1,600 – $2,400 / month<br/>(2-AZ, 70% Spot / 30% On-Demand, Karpenter Autoscaling)"]
    Scen2["SCENARIO 2: Production Baseline Environment (RECOMMENDED PROD)<br/>~$4,200 – $6,100 / month<br/>(3-AZ, 100% On-Demand / Savings Plans, Managed RDS MySQL)"]
    Scen3["SCENARIO 3: Production Enhanced High Availability<br/>~$7,200 – $10,500 / month<br/>(3-AZ, Amazon Aurora MySQL, ElastiCache Redis Cluster)"]
    Scen4["SCENARIO 4: Production with Cross-Region Disaster Recovery<br/>~$10,000 – $14,800 / month<br/>(Multi-AZ Primary Region + Cross-Region Pilot Light)"]

    Scen1 -->|Production Promotion| Scen2
    Scen2 -->|Enhance HA| Scen3
    Scen3 -->|Add Cross-Region DR| Scen4
```

---

## 3. Cost Breakdown Across Scenarios

| AWS Cost Component Category | Scenario 1 (Std Test) | Scenario 2 (Prod Base) | Scenario 3 (Prod HA) | Scenario 4 (Prod DR) |
| :--- | :--- | :--- | :--- | :--- |
| **EKS Control Plane** | $73 / mo | $73 / mo | $73 / mo | $146 / mo (2 Clusters) |
| **EC2 Worker Compute Nodes** | $450 / mo (70% Spot) | $1,800 / mo (Savings Plan)| $2,800 / mo | $4,200 / mo |
| **Database & Stateful Tier** | $445 / mo | $1,860 / mo (Managed RDS)| $3,800 / mo (Aurora) | $5,200 / mo (Multi-Region)|
| **Shared CI/CD Toolchain Stack**| $180 / mo (GitLab/Jenkins) | $371 / mo | $610 / mo (HA CI/CD) | $1,000 / mo |
| **Observability & Security Audit**| $201 / mo (OpenSearch/Prom)| $650 / mo | $1,550 / mo (Full APM) | $2,400 / mo |
| **Network & NAT Gateways** | $99 / mo (2 AZ NAT) | $99 / mo (3 AZ NAT) | $198 / mo (Transit GW) | $396 / mo |
| **Storage & Backups** | $120 / mo | $350 / mo | $600 / mo | $900 / mo (Cross-Region) |
| **Estimated Total Spend** | **~$1,600 – $2,400/mo**| **~$4,200 – $6,100/mo**| **~$7,200 – $10,500/mo**| **~$10,000 – $14,800/mo**|

---

## 4. Scenario-Specific System Architecture Diagrams

### 4.1 Scenario 1 Architecture: Standard Test Environment

![Scenario 1 Cost Architecture Diagram](../../../assets/scenario-1.png)
*Figure 4.1: Scenario 1 Architecture Diagram — Standard Test Environment ($1,600 – $2,400 / month).*

```mermaid
flowchart TB
    subgraph Edge["Perimeter Edge & Traffic Ingress Tier"]
        Users["External Users, QA Team & Mobile Clients"]
        CF["Cloudflare DNS, CDN & WAF"]
        IGW["AWS Internet Gateway<br/>Test VPC 10.100.0.0/16"]
        PublicALB["Public Application Load Balancer<br/>2 AZs<br/>Public Subnets 10.100.1.0/24 & 10.100.2.0/24"]
        NAT["2 NAT Gateways<br/>Outbound Egress"]

        Users -->|HTTPS TLS 1.3| CF
        CF --> IGW
        IGW --> PublicALB
    end

    subgraph ComputeTier["EKS Test/UAT Compute Tier — Private App Subnets 10.100.10.0/24 & 10.100.20.0/24"]
        EKSControl["Amazon EKS Managed Control Plane v1.30+"]
        IngressCtrl["AWS Load Balancer Controller"]
        Pods["40 Microservice Pods<br/>XS-S Specs<br/>HPA 70% CPU<br/>TopologySpread Across 2 AZs"]
        Karpenter["Karpenter JIT Autoscaler<br/>~8 Nodes<br/>70% Spot / 30% On-Demand<br/>m6g.large"]
        Nacos["Nacos 3-Node Raft Cluster<br/>StatefulSet Across 2 AZs"]
        ESO["External Secrets Operator"]
        TestJobs["Automated Test Jobs<br/>Smoke, Integration & Regression"]

        PublicALB --> IngressCtrl
        IngressCtrl --> Pods
        Karpenter --> Pods
        Pods --> Nacos
        ESO --> Pods
        TestJobs -->|API & Functional Tests| Pods
    end

    subgraph CICDTier["Shared CI/CD & GitOps Toolchain — VPC 10.200.0.0/16"]
        GitLab["GitLab Enterprise<br/>Application Source Repository"]
        Jenkins["Jenkins Controller"]
        JenkinsAgents["Dynamic Jenkins Spot Workers"]
        ECR["Amazon ECR Private Registry"]
        GitOpsRepo["GitOps Repository<br/>Helm Values / Kustomize Manifests"]
        ArgoCD["ArgoCD<br/>Single-Instance Test Deployment"]
        Ansible["Ansible Control Host<br/>Infrastructure Automation Only"]
        Approval["QA / UAT Approval Gate"]

        GitLab -->|Webhook| Jenkins
        Jenkins --> JenkinsAgents
        JenkinsAgents -->|Unit Test, Build, SAST, SCA, Trivy Scan| ECR
        JenkinsAgents -->|Update Image Digest / Tag| GitOpsRepo
        GitOpsRepo --> Approval
        Approval -->|Approved Merge| GitOpsRepo
        GitOpsRepo -->|Watch Desired State| ArgoCD
        ArgoCD -->|Sync via Kubernetes API| EKSControl
        EKSControl --> Pods

        Jenkins -->|Run Infrastructure Playbooks| Ansible
    end

    subgraph DatabaseTier["Isolated Database Tier — Zero-Internet Subnets 10.100.100.0/24 & 10.100.200.0/24"]
        RDS["RDS MySQL<br/>db.m6g.large Multi-AZ"]
        Redis["ElastiCache Redis<br/>cache.t4g.medium 2-Node"]
        RabbitMQ["Amazon MQ RabbitMQ<br/>mq.t3.micro Multi-AZ"]
        DocDB["Amazon DocumentDB<br/>db.t4g.medium 2-Node"]

        Pods -->|MySQL TLS| RDS
        Pods -->|Redis TLS| Redis
        Pods -->|AMQPS| RabbitMQ
        Pods -->|MongoDB TLS| DocDB
    end

    subgraph SecurityTier["Security & Secrets Management"]
        Secrets["AWS Secrets Manager"]
        KMS["AWS KMS Customer Managed Keys"]
        WAFLogs["Cloudflare & ALB Access Logs"]

        Secrets --> ESO
        KMS --> Secrets
        KMS --> RDS
        KMS --> Redis
        KMS --> ECR
        CF --> WAFLogs
        PublicALB --> WAFLogs
    end

    subgraph ObservabilityTier["Observability & Security Stack — VPC 10.300.0.0/16"]
        FluentBit["Fluent Bit DaemonSet"]
        OpenSearch["Amazon OpenSearch<br/>Single-Node Test Cluster"]
        S3["Amazon S3<br/>Velero Backup & Log Archive"]
        Prom["Prometheus & Grafana<br/>50GB EBS"]
        CW["CloudWatch, GuardDuty & AWS Config"]
        Notifications["Alert Notifications<br/>Email / Slack / Telegram"]

        Pods --> FluentBit
        FluentBit --> OpenSearch
        FluentBit --> S3
        Pods --> Prom
        EKSControl --> CW
        RDS --> CW
        PublicALB --> CW
        Prom --> Notifications
        CW --> Notifications
    end
```

---

### 4.2 Scenario 2 Architecture: Production Baseline Environment

![Scenario 2 Cost Architecture Diagram](../../../assets/scenario-2.png)
*Figure 4.2: Scenario 2 Architecture Diagram — Production Baseline Environment ($4,200 – $6,100 / month).*

```mermaid
flowchart TB
    subgraph Edge["Perimeter Edge & Traffic Ingress Tier"]
        Users["External Users & Mobile Clients"] -->|HTTPS TLS 1.3| CF["Cloudflare DNS, CDN & Enterprise WAF"]
        CF --> IGW["AWS Internet Gateway (Prod VPC 10.0.0.0/16)"]
        IGW --> PublicALB["Public Application Load Balancer (3 AZs - Public Subnets 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)"]
        NAT["3 NAT Gateways (AZ-a, AZ-b, AZ-c Egress)"]
    end

    subgraph ComputeTier["EKS Prod Compute Tier (Private App Subnets 10.0.10.0/24, 10.0.20.0/24, 10.0.30.0/24)"]
        EKSControl["Amazon EKS Managed Control Plane v1.30+ etcd HA ($73/mo)"]
        PublicALB --> IngressCtrl["AWS ALB Ingress Controller"]
        IngressCtrl --> Pods["40 Microservice Pods (S-M Specs, Multi-AZ TopologySpread)"]
        Karpenter["Karpenter JIT Autoscaler (~16 Nodes: 3-Yr Savings Plan m6g.xlarge) ($1,800/mo)"] --> Pods
        Pods --> Nacos["Nacos 3-Node Raft Cluster (StatefulSet Across 3 AZs)"]
    end

    subgraph SharedServices["Shared Services Account (VPC 10.200.0.0/16 - Dedicated Stack $371/mo)"]
        GitLab["GitLab Enterprise EC2 m6g.xlarge ($136/mo)"]
        Jenkins["Jenkins Master EC2 m6g.xlarge ($128/mo)"]
        JenkinsAgents["Dynamic Jenkins Workers EC2 Spot c6g.large ($25/mo)"]
        Ansible["Ansible Control Host EC2 t3.medium ($32/mo)"]
        ECR["Amazon ECR Private Registry ($50/mo)"]
        ArgoCD["ArgoCD Operator GitOps Sync"] --> Pods
    end

    subgraph DatabaseTier["Isolated Database Subnets (Zero-Internet 10.0.100.0/24, 10.0.200.0/24, 10.0.300.0/24 - $1,860/mo)"]
        Pods -->|MySQL Protocol| RDS["Amazon RDS MySQL db.m6g.xlarge Multi-AZ ($700/mo)"]
        Pods -->|Redis Protocol| Redis["Amazon ElastiCache Redis cache.m6g.large Multi-AZ ($200/mo)"]
        Pods -->|AMQP Protocol| RabbitMQ["Amazon MQ RabbitMQ mq.m6g.large Quorum 3-Node ($280/mo)"]
        Pods -->|Mongo Protocol| DocDB["Amazon DocumentDB db.r6g.xlarge 3-Node Cluster ($680/mo)"]
    end

    subgraph ObservabilityTier["Central Security & Observability Account (VPC 10.300.0.0/16 - $1,000/mo)"]
        Secrets["AWS Secrets Manager Vault"] -->|External Secrets Operator ESO| Pods
        KMS["AWS KMS CMK Keys Encryption"]
        Pods --> FluentBit["Fluent Bit DaemonSet Worker Nodes"]
        FluentBit --> OpenSearch["Amazon OpenSearch 2-Node r6g.large.search Cluster ($360/mo)"]
        FluentBit --> S3Glacier["Amazon S3 Archive & S3 Glacier Lock ($350/mo)"]
        Pods --> PromGraf["Prometheus & Grafana (100GB EBS + APM Metrics) ($160/mo)"]
        GuardDuty["AWS GuardDuty, AWS Config & X-Ray ($130/mo)"]
    end
```

---

### 4.3 Scenario 3 Architecture: Production Enhanced High Availability

![Scenario 3 Cost Architecture Diagram](../../../assets/scenario-3.png)
*Figure 4.3: Scenario 3 Architecture Diagram — Production Enhanced High Availability ($7,200 – $10,500 / month).*

```mermaid
flowchart TB
    subgraph Edge["Perimeter Edge & Traffic Ingress Tier"]
        Users["High-Volume External Users & Clients"] -->|HTTPS TLS 1.3| CF["Cloudflare Enterprise Global DNS, CDN & WAF"]
        CF --> IGW["AWS Internet Gateway (Prod High-Scale VPC 10.0.0.0/16)"]
        IGW --> PublicALB["Public High-Throughput ALBs (3 AZs - Public Subnets 10.0.1.0/24..3.0/24)"]
        NAT["3 NAT Gateways + AWS Transit Gateway Hub (10.250.0.0/16 - $198/mo)"]
    end

    subgraph ComputeTier["High-Scale EKS Compute Tier (Private App Subnets 10.0.10.0/24..30.0/24)"]
        EKSControl["Amazon EKS Managed Control Plane v1.30+ etcd HA ($73/mo)"]
        PublicALB --> IngressCtrl["AWS ALB Ingress Controller"]
        IngressCtrl --> Pods["40 Microservice Pods (M-L Specs, Auto-Scaling Replicas)"]
        Karpenter["Karpenter JIT Autoscaler (~28 Nodes: r6g.xlarge / c6g.2xlarge Mix) ($2,800/mo)"] --> Pods
        Pods --> Nacos["Nacos 3-Node Raft Cluster (High-Memory StatefulSet)"]
    end

    subgraph SharedServices["Enterprise Shared Services (VPC 10.200.0.0/16 - HA Cluster $610/mo)"]
        GitLab["GitLab HA 2-Node Cluster ($270/mo)"]
        Jenkins["Jenkins Master ASG + Dynamic Spot Agents ($180/mo)"]
        Ansible["Ansible HA Control Pair ($60/mo)"]
        ECR["Amazon ECR Multi-Region Registry ($100/mo)"]
        ArgoCD["ArgoCD GitOps Sync Controller"] --> Pods
    end

    subgraph DatabaseTier["Isolated Database Subnets (Zero-Internet 10.0.100.0/24..300.0/24 - $3,800/mo)"]
        Pods -->|Aurora Protocol| Aurora["Amazon Aurora MySQL db.r6g.xlarge 3 Replicas ($1,350/mo)"]
        Pods -->|Redis Sharded| Redis["ElastiCache Redis Sharded Cluster (3 Shards x 2 Replicas = 6 Nodes) ($600/mo)"]
        Pods -->|AMQP Quorum| RabbitMQ["Amazon MQ RabbitMQ mq.m6g.xlarge Quorum 3-Node ($550/mo)"]
        Pods -->|DocumentDB| DocDB["Amazon DocumentDB db.r6g.2xlarge 3-Node High-Spec ($1,300/mo)"]
    end

    subgraph ObservabilityTier["Security & High-Scale Observability Account (VPC 10.300.0.0/16 - $2,150/mo)"]
        Secrets["AWS Secrets Manager Vault"] --> Pods
        KMS["AWS KMS CMK Keys Encryption"]
        Pods --> FluentBit["Fluent Bit DaemonSet Worker Nodes"]
        FluentBit --> OpenSearch["Amazon OpenSearch 4-Node r6g.large.search Cluster ($850/mo)"]
        FluentBit --> S3Glacier["High-IOPS EBS (3TB) + S3 Glacier Vault Lock ($600/mo)"]
        Pods --> PromGraf["Prometheus HA + Thanos TSDB + Grafana APM ($400/mo)"]
        SecurityStack["GuardDuty, SecurityHub, AWS Config & X-Ray ($300/mo)"]
    end
```

---

### 4.4 Scenario 4 Architecture: Production with Cross-Region DR

![Scenario 4 Cost Architecture Diagram](../../../assets/scenario-4.png)
*Figure 4.4: Scenario 4 Architecture Diagram — Production Cross-Region Disaster Recovery ($10,000 – $14,800 / month).*

```mermaid
flowchart TB
    subgraph GlobalEdge["Global Edge & Failover Routing Tier"]
        Users["Global Web & Mobile Users"] -->|DNS Health Check Failover| GTM["Cloudflare Global Traffic Manager (GTM) / DNS"]
    end

    subgraph PrimaryRegion["Primary Active Region (us-east-1 3-AZ Production Footprint - $6,100 - $8,500/mo)"]
        GTM -->|Active Traffic| PrimALB["Primary AWS ALB Ingress Tier"]
        PrimALB --> PrimEKS["Primary EKS Cluster v1.30 (40 Microservice Pods)"]
        PrimEKS --> PrimRDS["Primary RDS MySQL Multi-AZ Primary & Standby"]
        PrimEKS --> PrimRedis["Primary ElastiCache Redis Cluster"]
        PrimEKS --> PrimDocDB["Primary Amazon DocumentDB 3-Node Cluster"]
        PrimEKS --> PrimOS["Primary OpenSearch Service Cluster"]
        PrimEKS --> PrimS3["Primary S3 Velero & Log Archive"]
    end

    subgraph CrossRegionSync["Cross-Region Replication & Disaster Recovery Layer ($800 - $1,600/mo)"]
        PrimRDS -->|RDS Cross-Region Snapshot Sync| DRRDS
        PrimS3 -->|S3 Cross-Region Replication CRR| DRS3
        PrimECR["Primary Amazon ECR"] -->|ECR Cross-Region Image Sync| DRECR["Secondary ECR"]
    end

    subgraph SecondaryDR["Secondary DR Standby Region (us-west-2 Pilot Light Footprint - $2,200 - $3,200/mo)"]
        GTM -- Automatic Failover RTO under 4h --> DRALB["Standby DR AWS ALB Ingress Tier"]
        DRALB --> DREKS["Pilot Light EKS Cluster (Standby Worker Nodes)"]
        DREKS --> DRRDS["Standby RDS MySQL Cross-Region Replica (db.m6g.large)"]
        DREKS --> DROS["Standby OpenSearch Mirror Node"]
        DREKS --> DRS3["Secondary Region S3 Backup Vault Lock ($900 - $1,500/mo)"]
    end
```
