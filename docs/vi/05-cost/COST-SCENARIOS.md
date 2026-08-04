# Mô hình Chi phí Theo Kịch bản: Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này trình bày các dự báo tài chính theo kịch bản cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng yêu cầu `BUS-004` và các quy tắc quản trị:
* Các ước tính chi phí là **dự báo dựa trên kịch bản**, không phải cam kết cố định đơn lẻ.
* Các số liệu đóng vai trò là cơ sở lập kế hoạch cho đến khi việc đo đạc tải thực tế (`Giai đoạn 0`) hoàn tất.

---

## 2. Bốn Kịch bản Chi phí Tài chính Doanh nghiệp

```mermaid
graph TD
    Scen1["KỊCH BẢN 1: Môi trường Test Tiêu chuẩn (KHUYẾN NGHỊ NON-PROD)<br/>~$1,600 – $2,400 / tháng<br/>(2-AZ, 70% Spot / 30% On-Demand, Karpenter Autoscaling)"]
    Scen2["KỊCH BẢN 2: Môi trường Production Cơ sở (KHUYẾN NGHỊ PROD)<br/>~$4,200 – $6,100 / tháng<br/>(3-AZ, 100% On-Demand / Savings Plans, Managed RDS MySQL)"]
    Scen3["KỊCH BẢN 3: Production Sẵn sàng Cao Nâng cao<br/>~$7,200 – $10,500 / tháng<br/>(3-AZ, Amazon Aurora MySQL, ElastiCache Redis Cluster)"]
    Scen4["KỊCH BẢN 4: Production có Khôi phục Thảm họa Xuyên Vùng<br/>~$10,000 – $14,800 / tháng<br/>(Multi-AZ Vùng Chính + Standby Pilot Light Vùng Thứ hai)"]

    Scen1 -->|Thăng cấp Production| Scen2
    Scen2 -->|Nâng cao Sẵn sàng Cao| Scen3
    Scen3 -->|Thêm Khôi phục Thảm họa DR| Scen4
```

---

## 3. Phân rã Chi phí Xuyên suốt 4 Kịch bản

| Danh mục Hạng mục Chi phí AWS | Kịch bản 1 (Test Tiêu chuẩn) | Kịch bản 2 (Prod Cơ sở) | Kịch bản 3 (Prod HA Nâng cao) | Kịch bản 4 (Prod DR Xuyên Vùng) |
| :--- | :--- | :--- | :--- | :--- |
| **EKS Control Plane** | $73 / tháng | $73 / tháng | $73 / tháng | $146 / tháng (2 Clusters) |
| **Nodes Tính toán Worker EC2** | $450 / tháng (70% Spot) | $1,800 / tháng (Savings Plan)| $2,800 / tháng | $4,200 / tháng |
| **Cơ sở Dữ liệu & Stateful** | $445 / tháng | $1,860 / tháng (Managed RDS)| $3,800 / tháng (Aurora) | $5,200 / tháng (Đa Vùng)|
| **Stack Công cụ CI/CD Dùng chung**| $180 / tháng (GitLab/Jenkins)| $371 / tháng | $610 / tháng (CI/CD HA) | $1,000 / tháng |
| **Bộ Quan sát & Kiểm toán Bảo mật**| $201 / tháng (OpenSearch/Prom)| $650 / tháng | $1,550 / tháng (APM Toàn diện) | $2,400 / tháng |
| **Mạng & NAT Gateways** | $99 / tháng (2 AZ NAT) | $99 / tháng (3 AZ NAT) | $198 / tháng (Transit GW) | $396 / tháng |
| **Lưu trữ & Sao lưu** | $120 / tháng | $350 / tháng | $600 / tháng | $900 / tháng (Cross-Region) |
| **Tổng Chi tiêu Ước tính** | **~$1,600 – $2,400/tháng**| **~$4,200 – $6,100/tháng**| **~$7,200 – $10,500/tháng**| **~$10,000 – $14,800/tháng**|

---

## 4. Các Sơ đồ Kiến trúc Hệ thống Chi tiết Theo Kịch bản

### 4.1 Kiến trúc Kịch bản 1: Môi trường Test Tiêu chuẩn (Non-Prod)

![Sơ đồ Kiến trúc Chi phí Kịch bản 1](../../../assets/scenario-1.png)
*Hình 4.1: Sơ đồ Kiến trúc Kịch bản 1 — Môi trường Test Tiêu chuẩn ($1,600 – $2,400 / tháng).*

```mermaid
flowchart TB
    subgraph Edge["Tầng Vành đai Edge & Ingress Public"]
        Users["Người dùng Cuối, Đội ngũ QA & Mobile Apps"]
        CF["Cloudflare DNS, CDN & WAF"]
        IGW["AWS Internet Gateway<br/>Test VPC 10.100.0.0/16"]
        PublicALB["Public Application Load Balancer<br/>2 AZs<br/>Subnets Public 10.100.1.0/24 & 10.100.2.0/24"]
        NAT["2 NAT Gateways<br/>Đầu ra Outbound Egress"]

        Users -->|HTTPS TLS 1.3| CF
        CF --> IGW
        IGW --> PublicALB
    end

    subgraph ComputeTier["Tầng Tính toán EKS Test/UAT — Subnets App Private 10.100.10.0/24 & 10.100.20.0/24"]
        EKSControl["Amazon EKS Managed Control Plane v1.30+"]
        IngressCtrl["AWS Load Balancer Controller"]
        Pods["40 Pods Microservices<br/>Cấu hình XS-S<br/>HPA 70% CPU<br/>TopologySpread trên 2 AZs"]
        Karpenter["Autoscaler Karpenter JIT<br/>~8 Nodes<br/>70% Spot / 30% On-Demand<br/>m6g.large"]
        Nacos["Nacos Raft Cluster 3-Node<br/>StatefulSet trên 2 AZs"]
        ESO["External Secrets Operator"]
        TestJobs["Kịch bản Kiểm thử Tự động<br/>Smoke, Integration & Regression"]

        PublicALB --> IngressCtrl
        IngressCtrl --> Pods
        Karpenter --> Pods
        Pods --> Nacos
        ESO --> Pods
        TestJobs -->|Kiểm thử API & Chức năng| Pods
    end

    subgraph CICDTier["Stack CI/CD & GitOps Dùng chung — VPC 10.200.0.0/16"]
        GitLab["GitLab Enterprise<br/>Kho Mã nguồn Ứng dụng"]
        Jenkins["Jenkins Controller"]
        JenkinsAgents["Jenkins Spot Workers Động"]
        ECR["Amazon ECR Private Registry"]
        GitOpsRepo["Kho GitOps Repository<br/>Helm Values / Kustomize Manifests"]
        ArgoCD["ArgoCD<br/>Single-Instance Test Deployment"]
        Ansible["Ansible Control Host<br/>Tự động hóa Hạ tầng"]
        Approval["Cổng Phê duyệt QA / UAT"]

        GitLab -->|Webhook| Jenkins
        Jenkins --> JenkinsAgents
        JenkinsAgents -->|Unit Test, Build, SAST, SCA, Quét Trivy| ECR
        JenkinsAgents -->|Cập nhật Image Digest / Tag| GitOpsRepo
        GitOpsRepo --> Approval
        Approval -->|Merge được Phê duyệt| GitOpsRepo
        GitOpsRepo -->|Theo dõi Trạng thái Mong muốn| ArgoCD
        ArgoCD -->|Đồng bộ qua Kubernetes API| EKSControl
        EKSControl --> Pods

        Jenkins -->|Chạy Playbooks Hạ tầng| Ansible
    end

    subgraph DatabaseTier["Tầng Database Cô lập — Zero-Internet Subnets 10.100.100.0/24 & 10.100.200.0/24"]
        RDS["RDS MySQL<br/>db.m6g.large Multi-AZ"]
        Redis["ElastiCache Redis<br/>cache.t4g.medium 2-Node"]
        RabbitMQ["Amazon MQ RabbitMQ<br/>mq.t3.micro Multi-AZ"]
        DocDB["Amazon DocumentDB<br/>db.t4g.medium 2-Node"]

        Pods -->|Giao thức MySQL TLS| RDS
        Pods -->|Giao thức Redis TLS| Redis
        Pods -->|Giao thức AMQPS| RabbitMQ
        Pods -->|Giao thức MongoDB TLS| DocDB
    end

    subgraph SecurityTier["Quản lý Bảo mật & Bí mật"]
        Secrets["AWS Secrets Manager"]
        KMS["AWS KMS CMK Keys Encryption"]
        WAFLogs["Access Logs Cloudflare & ALB"]

        Secrets --> ESO
        KMS --> Secrets
        KMS --> RDS
        KMS --> Redis
        KMS --> ECR
        CF --> WAFLogs
        PublicALB --> WAFLogs
    end

    subgraph ObservabilityTier["Stack Quan sát & Bảo mật — VPC 10.300.0.0/16"]
        FluentBit["Fluent Bit DaemonSet"]
        OpenSearch["Amazon OpenSearch<br/>Single-Node Test Cluster"]
        S3["Amazon S3<br/>Velero Backup & Log Archive"]
        Prom["Prometheus & Grafana<br/>50GB EBS"]
        CW["CloudWatch, GuardDuty & AWS Config"]
        Notifications["Thông báo Cảnh báo<br/>Email / Slack / Telegram"]

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

### 4.2 Kiến trúc Kịch bản 2: Môi trường Production Cơ sở

![Sơ đồ Kiến trúc Chi phí Kịch bản 2](../../../assets/scenario-2.png)
*Hình 4.2: Sơ đồ Kiến trúc Kịch bản 2 — Môi trường Production Cơ sở ($4,200 – $6,100 / tháng).*

```mermaid
flowchart TB
    subgraph Edge["Tầng Vành đai Edge & Ingress Public"]
        Users["Người dùng Cuối & Apps Doanh nghiệp"] -->|HTTPS TLS 1.3| CF["Cloudflare DNS, CDN & Enterprise WAF"]
        CF --> IGW["AWS Internet Gateway (VPC Prod 10.0.0.0/16)"]
        IGW --> PublicALB["Public Application Load Balancer (3 AZs - Subnets Public 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)"]
        NAT["3 NAT Gateways (Đầu ra Outbound AZ-a, AZ-b, AZ-c)"]
    end

    subgraph ComputeTier["Tầng Tính toán EKS Prod (Subnets App Private 10.0.10.0/24, 10.0.20.0/24, 10.0.30.0/24)"]
        EKSControl["Amazon EKS Managed Control Plane v1.30+ etcd HA ($73/tháng)"]
        PublicALB --> IngressCtrl["AWS ALB Ingress Controller"]
        IngressCtrl --> Pods["40 Pods Microservices (Cấu hình S-M, Anti-Affinity Multi-AZ)"]
        Karpenter["Autoscaler Karpenter JIT (~16 Nodes: Savings Plan 3 năm m6g.xlarge) ($1,800/tháng)"] --> Pods
        Pods --> Nacos["Nacos 3-Node Raft Cluster (StatefulSet trên 3 AZs)"]
    end

    subgraph SharedServices["Tài khoản Shared Services (VPC 10.200.0.0/16 - Dedicated Stack $371/tháng)"]
        GitLab["GitLab Enterprise EC2 m6g.xlarge ($136/tháng)"]
        Jenkins["Jenkins Master EC2 m6g.xlarge ($128/tháng)"]
        JenkinsAgents["Dynamic Jenkins Workers EC2 Spot c6g.large ($25/tháng)"]
        Ansible["Ansible Control Host EC2 t3.medium ($32/tháng)"]
        ECR["Amazon ECR Private Registry ($50/tháng)"]
        ArgoCD["Controller ArgoCD Đồng bộ GitOps"] --> Pods
    end

    subgraph DatabaseTier["Subnets Database Cô lập (Zero-Internet 10.0.100.0/24, 10.0.200.0/24, 10.0.300.0/24 - $1,860/tháng)"]
        Pods -->|Giao thức MySQL| RDS["Amazon RDS MySQL db.m6g.xlarge Multi-AZ ($700/tháng)"]
        Pods -->|Giao thức Redis| Redis["Amazon ElastiCache Redis cache.m6g.large Multi-AZ ($200/tháng)"]
        Pods -->|Giao thức AMQP| RabbitMQ["Amazon MQ RabbitMQ mq.m6g.large Quorum 3-Node ($280/tháng)"]
        Pods -->|Giao thức Mongo| DocDB["Amazon DocumentDB db.r6g.xlarge Cluster 3-Node ($680/tháng)"]
    end

    subgraph ObservabilityTier["Tài khoản Security & Observability Trung tâm (VPC 10.300.0.0/16 - $1,000/tháng)"]
        Secrets["AWS Secrets Manager Vault"] -->|External Secrets Operator ESO| Pods
        KMS["Mã hóa KMS CMK Keys"]
        Pods --> FluentBit["Fluent Bit DaemonSet Worker Nodes"]
        FluentBit --> OpenSearch["Amazon OpenSearch Cluster 2-Node r6g.large.search ($360/tháng)"]
        FluentBit --> S3Glacier["Amazon S3 Archive & S3 Glacier Vault Lock ($350/tháng)"]
        Pods --> PromGraf["Prometheus & Grafana (100GB EBS + APM Metrics) ($160/tháng)"]
        GuardDuty["AWS GuardDuty, AWS Config & X-Ray ($130/tháng)"]
    end
```

---

### 4.3 Kiến trúc Kịch bản 3: Production Sẵn sàng Cao Nâng cao

![Sơ đồ Kiến trúc Chi phí Kịch bản 3](../../../assets/scenario-3.png)
*Hình 4.3: Sơ đồ Kiến trúc Kịch bản 3 — Production Sẵn sàng Cao Nâng cao ($7,200 – $10,500 / tháng).*

```mermaid
flowchart TB
    subgraph Edge["Tầng Vành đai Edge & Ingress Tải lớn"]
        Users["Truy cập Người dùng & App Tải cao"] -->|HTTPS TLS 1.3| CF["Cloudflare Enterprise Global DNS, CDN & WAF"]
        CF --> IGW["AWS Internet Gateway (VPC Prod High-Scale 10.0.0.0/16)"]
        IGW --> PublicALB["Public High-Throughput ALBs (3 AZs - Subnets Public 10.0.1.0/24..3.0/24)"]
        NAT["3 NAT Gateways + AWS Transit Gateway Hub (10.250.0.0/16 - $198/tháng)"]
    end

    subgraph ComputeTier["Tầng Tính toán EKS Tải cao (Subnets App Private 10.0.10.0/24..30.0/24)"]
        EKSControl["Amazon EKS Managed Control Plane v1.30+ etcd HA ($73/tháng)"]
        PublicALB --> IngressCtrl["AWS ALB Ingress Controller"]
        IngressCtrl --> Pods["40 Pods Microservices (Cấu hình M-L, Auto-Scaling Replicas)"]
        Karpenter["Autoscaler Karpenter JIT (~28 Nodes: Mix r6g.xlarge / c6g.2xlarge) ($2,800/tháng)"] --> Pods
        Pods --> Nacos["Nacos Cluster 3-Node Raft (StatefulSet Bộ nhớ lớn)"]
    end

    subgraph SharedServices["Dịch vụ Dùng chung Doanh nghiệp (VPC 10.200.0.0/16 - Cluster HA $610/tháng)"]
        GitLab["GitLab HA Cluster 2-Node ($270/tháng)"]
        Jenkins["Jenkins Master ASG + Dynamic Spot Agents ($180/tháng)"]
        Ansible["Ansible HA Control Pair ($60/tháng)"]
        ECR["Amazon ECR Multi-Region Registry ($100/tháng)"]
        ArgoCD["Controller ArgoCD Đồng bộ GitOps"] --> Pods
    end

    subgraph DatabaseTier["Subnets Database Cô lập (Zero-Internet 10.0.100.0/24..300.0/24 - $3,800/tháng)"]
        Pods -->|Giao thức Aurora| Aurora["Amazon Aurora MySQL db.r6g.xlarge 3 Replicas ($1,350/tháng)"]
        Pods -->|Redis Sharded| Redis["ElastiCache Redis Cluster Sharded (3 Shards x 2 Replicas = 6 Nodes) ($600/tháng)"]
        Pods -->|AMQP Quorum| RabbitMQ["Amazon MQ RabbitMQ mq.m6g.xlarge Quorum 3-Node ($550/tháng)"]
        Pods -->|DocumentDB| DocDB["Amazon DocumentDB db.r6g.2xlarge 3-Node Cấu hình cao ($1,300/tháng)"]
    end

    subgraph ObservabilityTier["Tài khoản Security & Observability Quy mô lớn (VPC 10.300.0.0/16 - $2,150/tháng)"]
        Secrets["AWS Secrets Manager Vault"] --> Pods
        KMS["Mã hóa KMS CMK Keys"]
        Pods --> FluentBit["Fluent Bit DaemonSet Worker Nodes"]
        FluentBit --> OpenSearch["Amazon OpenSearch Cluster 4-Node r6g.large.search ($850/tháng)"]
        FluentBit --> S3Glacier["EBS High-IOPS (3TB) + S3 Glacier Vault Lock ($600/tháng)"]
        Pods --> PromGraf["Prometheus HA + Thanos TSDB + Grafana APM ($400/tháng)"]
        SecurityStack["GuardDuty, SecurityHub, AWS Config & X-Ray ($300/tháng)"]
    end
```

---

### 4.4 Kiến trúc Kịch bản 4: Production có Khôi phục Thảm họa Xuyên Vùng

![Sơ đồ Kiến trúc Chi phí Kịch bản 4](../../../assets/scenario-4.png)
*Hình 4.4: Sơ đồ Kiến trúc Kịch bản 4 — Production Khôi phục Thảm họa Xuyên Vùng ($10,000 – $14,800 / tháng).*

```mermaid
flowchart TB
    subgraph GlobalEdge["Tầng Vành đai Toàn cầu & Định tuyến Failover"]
        Users["Người dùng Web & Mobile Toàn cầu"] -->|Định tuyến Failover Kiểm tra Sức khỏe DNS| GTM["Cloudflare Global Traffic Manager (GTM) / DNS"]
    end

    subgraph PrimaryRegion["Vùng Chính Active (Dấu chân Production 3-AZ us-east-1 - $6,100 - $8,500/tháng)"]
        GTM -->|Luồng Traffic Active| PrimALB["Tầng ALB Ingress AWS Vùng Chính"]
        PrimALB --> PrimEKS["Cluster EKS Vùng Chính v1.30 (40 Pods Microservices)"]
        PrimEKS --> PrimRDS["RDS MySQL Multi-AZ Primary & Standby Vùng Chính"]
        PrimEKS --> PrimRedis["Cluster ElastiCache Redis Vùng Chính"]
        PrimEKS --> PrimDocDB["Cluster Amazon DocumentDB 3-Node Vùng Chính"]
        PrimEKS --> PrimOS["Cluster OpenSearch Service Vùng Chính"]
        PrimEKS --> PrimS3["Kho S3 Velero & Log Archive Vùng Chính"]
    end

    subgraph CrossRegionSync["Lớp Đồng bộ Nhân bản Xuyên Vùng & DR ($800 - $1,600/tháng)"]
        PrimRDS -->|RDS Cross-Region Snapshot Sync| DRRDS
        PrimS3 -->|S3 Cross-Region Replication CRR| DRS3
        PrimECR["Amazon ECR Vùng Chính"] -->|Đồng bộ Ảnh ECR Xuyên Vùng| DRECR["ECR Vùng Thứ hai"]
    end

    subgraph SecondaryDR["Vùng DR Standby Thứ hai (us-west-2 Dấu chân Pilot Light - $2,200 - $3,200/tháng)"]
        GTM -- Chuyển vùng Tự động RTO dưới 4h --> DRALB["Tầng ALB Ingress AWS DR Standby"]
        DRALB --> DREKS["Cluster EKS Pilot Light (Nodes Worker Standby)"]
        DREKS --> DRRDS["RDS MySQL Replica Xuyên Vùng Standby (db.m6g.large)"]
        DREKS --> DROS["Node OpenSearch Mirror Standby"]
        DREKS --> DRS3["S3 Backup Vault Lock Vùng Thứ hai ($900 - $1,500/tháng)"]
    end
```
