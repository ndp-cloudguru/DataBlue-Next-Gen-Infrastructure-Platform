# 成本假设与定价基准说明书 (Cost Assumptions: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了构建 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **参数化成本模型** 所使用的所有财务与技术假设。

根据需求 `BUS-004` 及治理规则：
* 成本估算为 **基于场景的预测 (场景 1 至 4)**，而非保证的单一账单。
* 所有定价均使用标准的 AWS 公有区域定价基准 (`us-east-1` / `ap-southeast-1` 费率)。
* 未确认的容量参数受受控的临服务代号规格 (Class XS, S, M, L, XL) 约束。

---

## 2. 核心财务与技术假设 (Core Financial & Technical Assumptions)

### 1. 计算与 EKS 控制平面
* **EKS 控制平面**: 每个环境每集群每小时固定 $0.10 (每集群每月 $73.00) (`ADR-003`)。
* **工作节点实例定价模型**:
  * 生产环境: 100% On-Demand 基础定价；3 年期 Compute Savings Plans 可获得约 30-40% 优惠。
  * 测试环境: 70% EC2 Spot 实例 (相比 On-Demand 约 70% 折扣) + 30% On-Demand (`ADR-005`)。
* **临时代号微服务资源密度**: ~40 个微服务分布在各个规格等级中：
  * Class XS (微型): 0.1 vCPU, 0.25 GB RAM (10 个服务)
  * Class S (小型): 0.25 vCPU, 0.5 GB RAM (15 个服务)
  * Class M (中型): 0.5 vCPU, 1.0 GB RAM (10 个服务)
  * Class L (大型): 1.0 vCPU, 2.0 GB RAM (5 个服务)

### 2. 网络与数据传输
* **NAT 网关**: 每 NAT 网关每小时 $0.045 (每个 AZ 每月 $32.85) + 处理数据每 GB $0.045。
* **跨可用区数据传输**: VPC 内部跨 AZ 流量每 GB $0.01。（通过 Kubernetes 拓扑感知路由优化）。
* **公网出站**: 前 10 TB/月流向公网的数据传输每 GB $0.09。

### 3. 数据库与有状态中间件层
* **关系型 MySQL (`FUN-005`)**: 托管 Amazon RDS MySQL `db.m6g.xlarge` Multi-AZ ($0.76/小时) 或 EKS 自建。
* **内存级 Redis (`FUN-008`)**: 托管 Amazon ElastiCache `cache.m6g.large` Multi-AZ ($0.136/小时) 或 EKS 自建。
* **消息代理 RabbitMQ (`FUN-006`)**: Amazon MQ `mq.m6g.large` Multi-AZ ($0.576/小时) 或 EKS 自建 Operator。
* **文档数据库 MongoDB (`FUN-007`)**: Amazon DocumentDB `db.t4g.medium` / `db.r6g.xlarge` 或 MongoDB Atlas SaaS 或 EKS 自建 Operator。

### 4. 存储与备份生命周期
* **EBS 存储 (`gp3`)**: $0.08 每 GB-月 + 超过 3,000 基础 IOPS 的预置 IOPS 每单项 $0.005。
* **S3 Standard 存储**: 活动备份快照及日志导出每 GB-月 $0.023。
* **S3 Glacier 灵活检索**: 长期日志归档（30 天后）每 GB-月 $0.004。
* **AWS Backup 快照**: RDS/EBS 备份存储每 GB-月 $0.05 (`ADR-013`)。

### 5. 可观测性与日志写入
* **Amazon OpenSearch**: 2 节点 `r6g.large.search` 集群 ($0.163/小时)，用于 7 天热日志搜索 (`ADR-012`)。
* **CloudWatch 写入**: 写入日志数据每 GB $0.50；在 Fluent Bit DaemonSet 层过滤 Debug 日志优化 (`RSK-CST-002`)。

### 6. 支持与运维开销
* **AWS Enterprise Support**: 生产账号 AWS 月度支出的 10%。
