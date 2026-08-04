# Parametric Cost Model & Detailed Formulas: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the complete **Parametric Cost Calculation Methodology**, mathematical formulas, variable definitions, unit pricing parameters, and detailed annotations for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirement `BUS-004` and [`REQUIREMENTS-REGISTER.md`](../01-requirements/REQUIREMENTS-REGISTER.md), the total monthly operational cost of the platform is calculated as the sum of six core cost categories:

$$\text{Total Monthly AWS Cost} = C_{\text{Fixed Platform}} + C_{\text{Compute Workload}} + C_{\text{Middleware}} + C_{\text{Storage/Backup}} + C_{\text{Network}} + C_{\text{Observability}}$$

---

## 2. Master Cost Calculation Formulas & Parameter Annotations

### 2.1 Fixed Platform Infrastructure Cost ($C_{\text{Fixed Platform}}$)

The fixed platform cost represents the non-negotiable base infrastructure required to keep EKS control planes, VPC networking, and edge load balancers operational 24/7/365 regardless of application load.

$$C_{\text{Fixed Platform}} = (N_{\text{Clusters}} \times P_{\text{EKS Control Plane}}) + (N_{\text{VPCs}} \times N_{\text{AZs}} \times P_{\text{NAT Gateway Hour}}) + (N_{\text{ALBs}} \times P_{\text{ALB Hour}})$$

#### Parameter Definitions & Annotations:
* $N_{\text{Clusters}}$: Number of active Amazon EKS clusters ($N = 2$: 1 Test Cluster + 1 Production Cluster).
* $P_{\text{EKS Control Plane}}$: Hourly rate for EKS managed control plane ($\text{USD } 0.10/\text{hour} \approx \text{USD } 73.00/\text{month per cluster}$).
* $N_{\text{VPCs}}$: Number of isolated Virtual Private Clouds ($N = 2$: 1 Test VPC + 1 Prod VPC).
* $N_{\text{AZs}}$: Number of Availability Zones per VPC ($N = 2$ for Test, $N = 3$ for Prod).
* $P_{\text{NAT Gateway Hour}}$: Hourly base charge per NAT Gateway ($\text{USD } 0.045/\text{hour} \approx \text{USD } 32.85/\text{month per gateway}$).
* $N_{\text{ALBs}}$: Number of AWS Application Load Balancers ($N = 2$: 1 Test Public ALB + 1 Prod Public ALB).
* $P_{\text{ALB Hour}}$: Hourly base charge per ALB ($\text{USD } 0.0225/\text{hour} \approx \text{USD } 16.425/\text{month per ALB}$).

#### Base Calculation:
$$C_{\text{Fixed Platform}} = (2 \times 73.00) + (1 \times 2 \times 32.85 + 1 \times 3 \times 32.85) + (2 \times 16.425) = 146.00 + 164.25 + 32.85 = \text{USD } 343.10/\text{month}$$

---

### 2.2 Compute Workload Cost ($C_{\text{Compute Workload}}$)

The compute workload cost covers the worker node EC2 capacity dynamically provisioned by **Karpenter Just-in-Time (JIT) Autoscaler** ([`ADR-005`](../03-decisions/ADR-005-karpenter-autoscaler.md)) to host ~40 microservice Pods.

$$C_{\text{Compute Workload}} = \sum_{i=1}^{N_{\text{Nodes}}} \left( \text{vCPU}_i \times P_{\text{vCPU-Hour}} + \text{RAM}_i \times P_{\text{RAM-Hour}} \right) \times 730 \times (1 - D_{\text{Pricing Plan}})$$

#### Parameter Definitions & Annotations:
* $N_{\text{Nodes}}$: Total number of active worker nodes running in the cluster.
* $\text{vCPU}_i$: vCPU capacity provisioned on node $i$ (e.g., `m6g.large` = 2 vCPUs).
* $\text{RAM}_i$: Memory capacity in GB provisioned on node $i$ (e.g., `m6g.large` = 8 GB RAM).
* $P_{\text{vCPU-Hour}}$: Baseline hourly cost per Graviton3 ARM64 vCPU ($\approx \text{USD } 0.0255/\text{vCPU-hour}$).
* $P_{\text{RAM-Hour}}$: Baseline hourly cost per GB RAM ($\approx \text{USD } 0.0034/\text{GB-hour}$).
* $D_{\text{Pricing Plan}}$: Financial discount factor applied based on purchasing tier:
  * **Test Environment (Spot)**: $D_{\text{Spot}} = 0.70$ (70% savings via Karpenter Spot Node Pools).
  * **Production Environment (Savings Plans)**: $D_{\text{Savings Plan}} = 0.35$ (35% savings via 3-Year Compute Savings Plans).

---

### 2.3 Stateful Middleware Tier Cost ($C_{\text{Middleware}}$)

The stateful middleware cost covers the 5 core persistence and messaging platforms required by the application domain: Relational DB (MySQL), In-Memory Cache (Redis), Message Queue (RabbitMQ), Document Store (MongoDB), and Configuration Center (Nacos).

$$C_{\text{Middleware}} = C_{\text{MySQL}} + C_{\text{Redis}} + C_{\text{RabbitMQ}} + C_{\text{MongoDB}} + C_{\text{Nacos}}$$

#### Parameter Definitions & Annotations:
* $C_{\text{MySQL}}$: **Amazon RDS MySQL Multi-AZ** (or **Amazon Aurora MySQL** in High-Scale HA Scenario 3) (`db.m6g.xlarge` Primary + Multi-AZ Standby = $\text{USD } 520.00 - 1,450.00/\text{month}$).
* $C_{\text{Redis}}$: **Amazon ElastiCache for Redis Multi-AZ** (`cache.m6g.large` 2-Node Cluster = $\text{USD } 140.00 - 480.00/\text{month}$).
* $C_{\text{RabbitMQ}}$: **Amazon MQ for RabbitMQ** (Quorum Broker 3-node HA = $\text{USD } 280.00 - 420.00/\text{month}$).
* $C_{\text{MongoDB}}$: **Amazon DocumentDB 3-Node Cluster** (`db.t4g.medium` or `db.m6g.large` = $\text{USD } 220.00 - 680.00/\text{month}$).
* $C_{\text{Nacos}}$: **3-Node Raft Consensus Cluster** running as Kubernetes StatefulSets on EKS compute ($\text{USD } 90.00 - 180.00/\text{month}$).

---

### 2.4 Storage & Backup Cost ($C_{\text{Storage/Backup}}$)

The storage cost includes block storage volumes for EKS nodes, database storage, object storage for assets, and snapshot backup archives.

$$C_{\text{Storage/Backup}} = (V_{\text{EBS gp3}} \times P_{\text{EBS}}) + (IOPS_{\text{Extra}} \times P_{\text{IOPS}}) + (V_{\text{S3 Standard}} \times P_{\text{S3 Standard}}) + (V_{\text{S3 Glacier}} \times P_{\text{Glacier}}) + (V_{\text{Snapshots}} \times P_{\text{Snapshot}})$$

#### Parameter Definitions & Annotations:
* $V_{\text{EBS gp3}}$: Provisioned EBS gp3 storage volume capacity in GB ($P_{\text{EBS}} = \text{USD } 0.08/\text{GB-month}$).
* $IOPS_{\text{Extra}}$: Provisioned IOPS exceeding baseline 3,000 IOPS per volume ($P_{\text{IOPS}} = \text{USD } 0.005/\text{provisioned IOPS-month}$).
* $V_{\text{S3 Standard}}$: Active object storage volume in GB ($P_{\text{S3 Standard}} = \text{USD } 0.023/\text{GB-month}$).
* $V_{\text{S3 Glacier}}$: Deep long-term compliance archive volume in GB ($P_{\text{Glacier}} = \text{USD } 0.004/\text{GB-month}$).
* $V_{\text{Snapshots}}$: Automated EBS and RDS point-in-time database snapshot storage ($P_{\text{Snapshot}} = \text{USD } 0.05/\text{GB-month}$).

---

### 2.5 Network & Data Transfer Cost ($C_{\text{Network}}$)

The network cost covers data processed through NAT Gateways, cross-AZ traffic within AWS regions, and internet egress.

$$C_{\text{Network}} = (G_{\text{NAT Processed}} \times P_{\text{NAT Data}}) + (G_{\text{Inter-AZ Data}} \times P_{\text{Inter-AZ}}) + (G_{\text{Internet Out}} \times P_{\text{Egress}})$$

#### Parameter Definitions & Annotations:
* $G_{\text{NAT Processed}}$: Data processed by NAT Gateways in GB ($P_{\text{NAT Data}} = \text{USD } 0.045/\text{GB}$).
* $G_{\text{Inter-AZ Data}}$: Inter-Availability Zone traffic between EKS pods and Multi-AZ databases ($P_{\text{Inter-AZ}} = \text{USD } 0.01/\text{GB in/out}$).
* $G_{\text{Internet Out}}$: Outbound data transfer to external end users and partners ($P_{\text{Egress}} = \text{USD } 0.09/\text{GB}$).

---

### 2.6 Observability & Management Cost ($C_{\text{Observability}}$)

The observability cost covers central logging, Prometheus/Grafana metrics monitoring, and audit trails.

$$C_{\text{Observability}} = C_{\text{OpenSearch Cluster}} + (G_{\text{Logs Ingested}} \times P_{\text{Ingest}}) + (G_{\text{S3 Log Archive}} \times P_{\text{Archive}})$$

#### Parameter Definitions & Annotations:
* $C_{\text{OpenSearch Domain}}$: **Amazon OpenSearch Service** (2-node or 4-node cluster for log indexing = $\text{USD } 180.00 - 650.00/\text{month}$).
* $G_{\text{Logs Ingested}}$: Total application log volume ingested by Fluent Bit daemonset ($P_{\text{Ingest}} = \text{USD } 0.50/\text{GB}$).
* $G_{\text{S3 Log Archive}}$: Long-term S3 log archive storage ($P_{\text{Archive}} = \text{USD } 0.004/\text{GB-month}$).

---

## 3. Financial Cost Scenarios Summary

Applying the parametric model across the four normalized project scenarios yields the following budget baselines:

| Financial Cost Scenario | EKS Layout & Specs | Middleware Topology | Monthly Budget Baseline | Primary Architectural Role |
| :--- | :--- | :--- | :--- | :--- |
| **Scenario 1: Standard Non-Prod Test Baseline** | 2 AZs, ~8 `m6g.large` Nodes, 70% Spot | Single-Instance / Lightweight DBs | **USD 1,600 – 2,400 / month** | Non-Production Test & QA Validation |
| **Scenario 2: Production Baseline** | 3 AZs, ~12 `m6g.large` Nodes, 3-Yr Savings Plans | RDS MySQL Multi-AZ, OpenSearch 2-Node | **USD 4,200 – 6,100 / month** | Production Launch Baseline |
| **Scenario 3: Production High-Scale HA** | 3 AZs, Transit Gateway, ~24 Nodes | Aurora MySQL 3 Replicas, Redis Sharded | **USD 7,200 – 10,500 / month** | High-Traffic Production Peak Load |
| **Scenario 4: Production Cross-Region DR** | Primary `us-east-1` + Standby `us-west-2` | Cross-Region Replication, Cloudflare GTM | **USD 10,000 – 14,800 / month** | Full Multi-Region Disaster Recovery |
