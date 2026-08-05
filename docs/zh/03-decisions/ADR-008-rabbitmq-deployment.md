# ADR-008 — RabbitMQ 消息代理部署架构策略 (RabbitMQ Deployment Strategy)

## 元数据 (Metadata)
* **状态**: `暂缓/待定 (Deferred)`
* **日期**: 2026-08-03
* **决策负责人**: 数据架构主工程师 (Lead Data Architect), 云基础设施 Lead (Cloud Infrastructure Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), DevOps 团队 (DevOps Lead)
* **关联需求**: [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-UNC-001` (缺少消息吞吐量数据), `RSK-OPS-001` (消息代理有状态复杂度)
* **关联假设**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 3 节, 第 6 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `FUN-006` 规定需要 RabbitMQ 消息代理服务，用于跨业务系统的异步事件流与服务间消息通信。我们必须确定是在 EKS 上通过官方 K8s Cluster Operator 部署 RabbitMQ、采用 Amazon MQ for RabbitMQ 托管服务，还是搭建独立的 EC2 集群。目前尚缺少消息吞吐量 (msg/sec)、队列持久化及 Payload 大小指标 (`OPEN-001`)。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **Quorum 队列韧性**: 多可用区消息镜像与持久化队列的耐用性 (`NFR-001`)。
2. **消息吞吐与延迟**: 低延迟的 AMQP 0-9-1 / MQTT 消息传递 (`FUN-006`)。
3. **运维开销**: 管理 Erlang VM 升级、集群网络分区（脑裂修复）及队列磁盘开销。
4. **成本架构**: 比较 Amazon MQ 托管 Broker 成本与 EKS 计算/EBS 存储成本 (`CST-001`)。

---

## 3. 约束条件 (Constraints)
* 必须支持标准 AMQP 协议与 RabbitMQ Quorum 队列。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: EKS 自建 RabbitMQ (官方 RabbitMQ Cluster Kubernetes Operator) — 领先候选方案
* **描述**: 使用 VMware/RabbitMQ 官方 Cluster Operator 在 EKS 内部部署 StatefulSets，后端由跨 3 可用区的 EBS `gp3` 卷提供存储。
* **优势**: 声明式 CRD 定义；原生 Kubernetes 集成；无 Amazon MQ 托管实例开销；易于保持本地开发环境一致性。
* **劣势**: SRE 团队必须监控 Erlang Mnesia 数据库状态、处理网络分区恢复并管理 EBS 存储扩展。
* **安全性影响**: 良好。TLS 传输加密、Pod SecurityContext 及 IAM IRSA 集成。
* **可用性影响**: 跨 3 可用区配置 Quorum 队列时表现强劲。
* **相关风险**: 跨可用区网络突发高峰期间 Erlang 网络分区脑裂风险。

### 方案 2: Amazon MQ for RabbitMQ (托管服务)
* **描述**: 使用 AWS 托管的 Amazon MQ 服务部署 Multi-AZ 主/备或集群。
* **优势**: AWS 管理 Broker 预置、OS/Erlang 补丁更新、搭建与多可用区复制。
* **劣势**: 显著偏高的小时实例定价；底层的 Erlang VM 配置访问权限受限；取决于实例类型的队列存储大小限制。
* **安全性影响**: 极佳。静态 KMS 加密、传输 TLS 加密、VPC 安全组隔离。
* **可用性影响**: 高 (99.9% SLA)。
* **运维影响**: DevOps 团队仅需极少的运维维护。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: EKS 自建 RabbitMQ Operator | 方案 2: Amazon MQ for RabbitMQ | 方案 3: 独立 EC2 集群 |
| :--- | :--- | :--- | :--- |
| **运维人力** | 中等 | **极低** | 沉重 |
| **K8s 原生集成 (`BUS-002`)** | **强 (原生 Operator)** | 中等 (AMQP 端点) | 中等 |
| **成本效益 (`CST-001`)** | **高** | 低 (高 AWS 溢价) | 中等 |
| **韧性 (Quorum Queues)** | **强** | 强 | 中等 |
| **可逆性** | **易于撤销** | 可逆 | 可逆 |

---

## 6. 提议决策 (Proposed Decision)
**暂缓/待定决策 (Decision Deferred)**。

---

## 7. 决策依据 (Rationale)
在完成消息量与吞吐量指标剖析 (`OPEN-001`) 之前，**暂缓对 EKS 自建 RabbitMQ Operator 与 Amazon MQ for RabbitMQ 做出最终选择**。

方案 1 目前由于标准 Operator 的成熟度和成本效益而处于技术领先地位，但需要针对客户的消息持久化目标进行实测验证。

---

## 8. 签署前所需的验证凭证
1. 微服务消息量 (msg/sec)、平均 Payload 大小及队列持久化目标 (`OPEN-001`)。
2. SRE 团队对 RabbitMQ / Erlang VM 的运维能力评估。

## 9. 验收条件 (Acceptance Conditions)
* 提交验证通过的消息传递基准测试并完成架构委员会签署。

## 10. 重新评估触发条件 (Revisit Triggers)
* 阶段 1 工作负载剖析完成。

## 11. 实施影响 (Implementation Implications)
* 平台架构为 RabbitMQ 路由分配 EKS Namespace 和网络终端。
