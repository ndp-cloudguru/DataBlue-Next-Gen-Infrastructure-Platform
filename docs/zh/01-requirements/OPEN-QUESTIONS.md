# 开放问题登记册 (Open Questions Register: DataBlue Next-Gen Platform)

---

## 1. 概述 (Overview)

本文档跟踪了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 中已排定优先级的开放式架构、运维与财务问题。

问题集中在重大影响的决策上，这些决策实质上影响着 AWS 架构设计、基础设施拓扑、安全边界以及 AWS 云支出。

---

## 2. 重大影响的架构与成本问题 (High-Impact Questions)

### `OPEN-001`: 微服务工作负载剖析与容量规划
* **影响级别**: **紧急 (CRITICAL)** (直接影响 EKS 节点选型、EC2 实例系列及 AWS 总成本)。
* **问题**: 跨 5–6 个业务系统的约 40 个微服务中，每个微服务的平均及峰值 CPU、内存、存储 IOPS 和网络吞吐量规格是什么？
* **为何重要**: 缺乏容量数据时，节点预置依赖于临时假设 (`ASM-006`)，存在过度消费或配置不足的风险。
* **目标决策阶段**: 阶段 1 / 阶段 2 (在最终确定 IaC 选型之前)。
* **所需行动**: 客户运行工作负载剖析工具或提供旧服务器指标。

---

### `OPEN-002`: 有状态中间件部署模型 (AWS 托管 vs EKS 自建)
* **影响级别**: **紧急 (CRITICAL)** (影响运维复杂度、备份/DR 自动化及 AWS 月度支出)。
* **问题**: 对于 MySQL、RabbitMQ、MongoDB、Redis 和 Nacos，组织更倾向于：
  1. 完全托管的 AWS 服务（如 AWS RDS MySQL、Amazon ElastiCache Redis、Amazon DocumentDB / MongoDB Atlas、Amazon MSK / EC2 上自建 RabbitMQ）？
  2. 直接部署在 EKS 内部的自建中间件 Operator（如 ECK、KubeBlocks、基于 EBS 持久卷的 Bitnami Helm Chart Operator）？
* **为何重要**: 托管服务降低运维负担但增加 AWS 账单成本；EKS Operator 减少云厂商绑定但需要专门的 SRE 维护。
* **目标决策阶段**: 阶段 1 (通过正式 ADR 进行评估)。
* **所需行动**: 架构团队提交 TCO 及运维复杂度对比报告。

---

### `OPEN-003`: 目标区域可用性与灾难恢复 (DR) SLA
* **影响级别**: **高 (HIGH)** (影响 RTO/RPO 需求、跨区域数据传输费及多区域架构)。
* **问题**: 在区域彻底停机期间，5–6 个业务系统各自的具体恢复时间目标 (RTO) 和恢复点目标 (RPO) 是什么？
* **为何重要**: 高可用 (单区域 Multi-AZ) 防止节点/可用区故障。完全灾难恢复 (跨区域故障转移) 需要主从或主主复制，基础成本翻倍。
* **目标决策阶段**: 阶段 1 ADR。
* **所需行动**: 业务产品负责人定义业务连续性分级。

---

### `OPEN-004`: 网络连接与本地 / 多云集成
* **影响级别**: **高 (HIGH)** (影响 AWS VPC CIDR 分配、Transit Gateway 搭建、AWS Direct Connect / VPN 成本)。
* **问题**: 5–6 个业务系统中是否有任何系统需要通过 AWS Direct Connect / Site-to-Site VPN 混合连接到本地数据中心、外部第三方支付网关或现有的旧数据库？
* **为何重要**: 决定 VPC 网络规划、NAT 网关吞吐量规格、传输路由及混合安全过滤策略。
* **目标决策阶段**: 阶段 1 架构设计。
* **所需行动**: 客户网络基础设施团队提供网络集成拓扑图。

---

### `OPEN-005`: 多账号治理与安全合规框架
* **影响级别**: **中-高 (MEDIUM-HIGH)** (影响 AWS Control Tower、IAM Identity Center / SSO、审计日志、合规范围)。
* **问题**: 组织是否强制执行特定的监管合规框架（如 PCI-DSS, ISO 27001, SOC2, HIPAA）？是否有现有的 AWS Organizations / Control Tower Landing Zone？
* **为何重要**: 决定安全策略边界、集中式 CloudTrail 日志聚合、KMS 密钥轮转规则及 IAM 集成。
* **目标决策阶段**: 阶段 0 / 阶段 1 治理对齐。
* **所需行动**: 客户安全与合规团队确认审计需求。

---

### `OPEN-006`: CI/CD 流水线自动化与治理边界
* **影响级别**: **中 (MEDIUM)** (影响开发者工作流、容器镜像仓库结构、密钥管理)。
* **问题**: 密钥（数据库凭据、API Key、证书）应如何在 GitLab → Jenkins → Ansible → EKS 部署流水线间注入（如 AWS Secrets Manager, HashiCorp Vault, 或 Sealed Secrets）？
* **为何重要**: 防止流水线硬编码密钥，建立安全的 GitOps / Ansible 执行原则。
* **目标决策阶段**: 阶段 2 详细技术设计。
* **所需行动**: DevOps 团队就密钥存储工具链达成一致。
