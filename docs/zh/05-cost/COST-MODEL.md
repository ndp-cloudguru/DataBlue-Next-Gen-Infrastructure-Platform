# 参数化成本计算模型与公式说明书 (Parametric Cost Model: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的完整 **参数化成本计算方法论**、数学公式、变量定义、单价参数及详细注释。

根据需求 `BUS-004` 及 [`REQUIREMENTS-REGISTER.md`](../01-requirements/REQUIREMENTS-REGISTER.md)，平台的月度总运营成本计算为 6 个核心成本分类的总和：

$$\text{月度 AWS 总成本} = C_{\text{固定平台}} + C_{\text{计算工作负载}} + C_{\text{中间件}} + C_{\text{存储与备份}} + C_{\text{网络}} + C_{\text{可观测性}}$$

---

## 2. 主成本计算公式与参数注释 (Master Formulas & Parameter Annotations)

### 2.1 固定平台基础设施成本 ($C_{\text{固定平台}}$)

固定平台成本代表不可谈判的基础基础设施，无论应用负载如何，都需要保持 EKS 控制平面、VPC 网络和边缘负载均衡器 24/7/365 运行。

$$C_{\text{固定平台}} = (N_{\text{集群}} \times P_{\text{EKS 控制平面}}) + (N_{\text{VPCs}} \times N_{\text{可用区}} \times P_{\text{NAT 网关小时}}) + (N_{\text{ALBs}} \times P_{\text{ALB 小时}})$$

#### 参数定义与注释:
* $N_{\text{集群}}$: 运行中的 Amazon EKS 集群数量 ($N = 2$: 1 个测试集群 + 1 个生产集群)。
* $P_{\text{EKS 控制平面}}$: EKS 托管控制平面的小时单价 ($\text{USD } 0.10/\text{小时} \approx \text{USD } 73.00/\text{月/集群}$)。
* $N_{\text{VPCs}}$: 隔离的 Virtual Private Cloud 数量 ($N = 2$: 1 个测试 VPC + 1 个生产 VPC)。
* $N_{\text{可用区}}$: 每个 VPC 的可用区数量 (测试环境 $N = 2$，生产环境 $N = 3$)。
* $P_{\text{NAT 网关小时}}$: 每个 NAT 网关的小时基础费用 ($\text{USD } 0.045/\text{小时} \approx \text{USD } 32.85/\text{月/网关}$)。
* $N_{\text{ALBs}}$: AWS Application Load Balancer 数量 ($N = 2$: 1 个测试公网 ALB + 1 个生产公网 ALB)。
* $P_{\text{ALB 小时}}$: 每个 ALB 的小时基础费用 ($\text{USD } 0.0225/\text{小时} \approx \text{USD } 16.425/\text{月/ALB}$)。

#### 基础计算:
$$C_{\text{固定平台}} = (2 \times 73.00) + (1 \times 2 \times 32.85 + 1 \times 3 \times 32.85) + (2 \times 16.425) = 146.00 + 164.25 + 32.85 = \text{USD } 343.10/\text{月}$$

---

### 2.2 计算工作负载成本 ($C_{\text{计算工作负载}}$)

计算工作负载成本涵盖了由 **Karpenter JIT 自动扩缩容引擎** ([`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md)) 动态拉起的 EC2 工作节点容量，用于托管约 40 个微服务 Pod。

$$C_{\text{计算工作负载}} = \sum_{i=1}^{N_{\text{节点}}} \left( \text{vCPU}_i \times P_{\text{vCPU-小时}} + \text{RAM}_i \times P_{\text{RAM-小时}} \right) \times 730 \times (1 - D_{\text{折扣计划}})$$

#### 参数定义与注释:
* $N_{\text{节点}}$: 集群中运行的活动工作节点总数。
* $\text{vCPU}_i$: 在节点 $i$ 上分配的 vCPU 容量（例如 `m6g.large` = 2 vCPUs）。
* $\text{RAM}_i$: 在节点 $i$ 上分配的内存容量 GB（例如 `m6g.large` = 8 GB RAM）。
* $P_{\text{vCPU-小时}}$: 每 Graviton3 ARM64 vCPU 的基础小时成本 ($\approx \text{USD } 0.0255/\text{vCPU-小时}$)。
* $P_{\text{RAM-小时}}$: 每 GB RAM 的基础小时成本 ($\approx \text{USD } 0.0034/\text{GB-小时}$)。
* $D_{\text{折扣计划}}$: 根据采购层级应用的财务折扣系数：
  * **测试环境 (Spot)**: $D_{\text{Spot}} = 0.70$ (通过 Karpenter Spot 节点池获得 70% 节约)。
  * **生产环境 (Savings Plans)**: $D_{\text{Savings Plan}} = 0.35$ (通过 3 年期 Compute Savings Plans 获得 35% 节约)。

---

### 2.3 有状态中间件层成本 ($C_{\text{中间件}}$)

有状态中间件成本涵盖应用域所需的 5 个核心持久化与消息平台：关系型 DB (MySQL)、内存缓存 (Redis)、消息队列 (RabbitMQ)、文档存储 (MongoDB) 及配置中心 (Nacos)。

$$C_{\text{中间件}} = C_{\text{MySQL}} + C_{\text{Redis}} + C_{\text{RabbitMQ}} + C_{\text{MongoDB}} + C_{\text{Nacos}}$$

#### 参数定义与注释:
* $C_{\text{MySQL}}$: **Amazon RDS MySQL Multi-AZ** (或大规模高可用场景 3 中的 **Amazon Aurora MySQL**) (`db.m6g.xlarge` 主节点 + Multi-AZ 备节点 = $\text{USD } 520.00 - 1,450.00/\text{月}$)。
* $C_{\text{Redis}}$: **Amazon ElastiCache for Redis Multi-AZ** (`cache.m6g.large` 2 节点集群 = $\text{USD } 140.00 - 480.00/\text{月}$)。
* $C_{\text{RabbitMQ}}$: **Amazon MQ for RabbitMQ** (Quorum Broker 3 节点 HA = $\text{USD } 280.00 - 420.00/\text{月}$)。
* $C_{\text{MongoDB}}$: **Amazon DocumentDB 3 节点集群** (`db.t4g.medium` 或 `db.m6g.large` = $\text{USD } 220.00 - 680.00/\text{月}$)。
* $C_{\text{Nacos}}$: **3 节点 Raft 共识集群** 作为 Kubernetes StatefulSets 运行在 EKS 计算节点上 ($\text{USD } 90.00 - 180.00/\text{月}$)。

---

### 2.4 存储与备份成本 ($C_{\text{存储与备份}}$)

存储成本包括 EKS 节点的块存储卷、数据库存储、资产对象存储以及快照备份归档。

$$C_{\text{存储与备份}} = (V_{\text{EBS gp3}} \times P_{\text{EBS}}) + (IOPS_{\text{额外}} \times P_{\text{IOPS}}) + (V_{\text{S3 Standard}} \times P_{\text{S3 Standard}}) + (V_{\text{S3 Glacier}} \times P_{\text{Glacier}}) + (V_{\text{Snapshots}} \times P_{\text{Snapshot}})$$

#### 参数定义与注释:
* $V_{\text{EBS gp3}}$: 分配的 EBS gp3 存储卷容量 GB ($P_{\text{EBS}} = \text{USD } 0.08/\text{GB-月}$)。
* $IOPS_{\text{额外}}$: 超过每个卷基础 3,000 IOPS 的预置 IOPS ($P_{\text{IOPS}} = \text{USD } 0.005/\text{预置 IOPS-月}$)。
* $V_{\text{S3 Standard}}$: 活动对象存储容量 GB ($P_{\text{S3 Standard}} = \text{USD } 0.023/\text{GB-月}$)。
* $V_{\text{S3 Glacier}}$: 长期合规深度归档容量 GB ($P_{\text{Glacier}} = \text{USD } 0.004/\text{GB-月}$)。
* $V_{\text{Snapshots}}$: 自动化的 EBS 及 RDS 时间点数据库快照存储 ($P_{\text{Snapshot}} = \text{USD } 0.05/\text{GB-月}$)。

---

### 2.5 网络与数据传输成本 ($C_{\text{网络}}$)

网络成本涵盖通过 NAT 网关处理的数据、AWS 区域内的跨可用区流量以及公网出站流量。

$$C_{\text{网络}} = (G_{\text{NAT 处理流量}} \times P_{\text{NAT 数据}}) + (G_{\text{跨 AZ 流量}} \times P_{\text{跨 AZ}}) + (G_{\text{公网出站}} \times P_{\text{出站}})$$

#### 参数定义与注释:
* $G_{\text{NAT 处理流量}}$: NAT 网关处理的数据量 GB ($P_{\text{NAT 数据}} = \text{USD } 0.045/\text{GB}$)。
* $G_{\text{跨 AZ 流量}}$: EKS Pods 与 Multi-AZ 数据库之间的跨可用区流量 ($P_{\text{跨 AZ}} = \text{USD } 0.01/\text{GB in/out}$)。
* $G_{\text{公网出站}}$: 发往外部终端用户与合作伙伴的出站数据传输 ($P_{\text{出站}} = \text{USD } 0.09/\text{GB}$)。

---

### 2.6 可观测性与管理成本 ($C_{\text{可观测性}}$)

可观测性成本涵盖集中式日志记录、Prometheus/Grafana 指标监控及审计日志。

$$C_{\text{可观测性}} = C_{\text{OpenSearch 集群}} + (G_{\text{写入日志}} \times P_{\text{写入}}) + (G_{\text{S3 日志归档}} \times P_{\text{归档}})$$

#### 参数定义与注释:
* $C_{\text{OpenSearch 域}}$: **Amazon OpenSearch Service** (用于日志索引的 2 节点或 4 节点集群 = $\text{USD } 180.00 - 650.00/\text{月}$)。
* $G_{\text{写入日志}}$: 由 Fluent Bit DaemonSet 写入的应用日志总量 ($P_{\text{写入}} = \text{USD } 0.50/\text{GB}$)。
* $G_{\text{S3 日志归档}}$: 长期 S3 日志归档存储 ($P_{\text{归档}} = \text{USD } 0.004/\text{GB-月}$)。

---

## 3. 财务成本场景汇总表 (Financial Cost Scenarios Summary)

将参数化模型应用到 4 个规范化的项目场景中，得出以下预算基线：

| 财务成本场景 | EKS 布局与规格 | 中间件拓扑 | 月度预算基线 | 主要架构角色 |
| :--- | :--- | :--- | :--- | :--- |
| **场景 1: 标准非生产测试基线** | 2 可用区, ~8 `m6g.large` 节点, 70% Spot | 单实例 / 轻量级 DBs | **USD 1,600 – 2,400 / 月** | 非生产测试与 QA 验证 |
| **场景 2: 生产基线** | 3 可用区, ~12 `m6g.large` 节点, 3 年 Savings Plans | RDS MySQL Multi-AZ, OpenSearch 2 节点 | **USD 4,200 – 6,100 / 月** | 生产上线基线 |
| **场景 3: 生产大规模高可用** | 3 可用区, Transit Gateway, ~24 节点 | Aurora MySQL 3 副本, Redis 分片 | **USD 7,200 – 10,500 / 月** | 高流量生产峰值负载 |
| **场景 4: 生产跨区域 DR** | 主区域 `us-east-1` + 备用区域 `us-west-2` | 跨区域复制, Cloudflare GTM | **USD 10,000 – 14,800 / 月** | 完全的多区域灾难恢复 |
