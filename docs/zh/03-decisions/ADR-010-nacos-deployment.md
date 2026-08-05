# ADR-010 — Nacos 服务注册与配置中心部署架构策略 (Nacos Deployment Strategy)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 应用架构主工程师 (Lead Application Architect), DevOps 负责人 (DevOps Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board)
* **关联需求**: [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-ARC-002` (Nacos 集群状态同步失败风险)
* **关联假设**: [`ASM-001`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 3 节, 第 6 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `FUN-009` 规定需要 Nacos 用于跨约 40 个微服务进行微服务服务注册、动态配置管理以及健康检查。我们必须决定是在 EKS 内部直接部署 Nacos、部署在独立的 EC2 实例上，还是使用其他替代工具链。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **服务间低延迟服务发现**: 为向 Nacos 注册的微服务提供亚秒级的 DNS / API 查找 (`FUN-009`)。
2. **高可用性与 Quorum 状态**: 跨多可用区 (Multi-AZ) 的 Nacos 集群 Raft Quorum 仲裁同步 (`NFR-001`)。
3. **需求合规性**: 满足客户关于 Nacos 兼容性的硬性需求，且无需重构应用代码。

---

## 3. 约束条件 (Constraints)
* 必须支持 Nacos 2.x+ 集群模式，并具备 MySQL 后端持久化支持。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: EKS 私有应用子网中部署 Nacos 集群 — 推荐方案
* **描述**: 在 EKS 内部将 Nacos 部署为跨 3 个可用区 (3 AZs) 私有应用子网的多副本 StatefulSet，由 MySQL 数据库层提供持久化配置存储。
* **优势**: 与微服务 Pod 之间实现亚毫秒级的集群内部通信；通过 Kubernetes Deployment/StatefulSet 实现自动化的 Pod 生命周期管理；零单独 EC2 实例开销。
* **劣势**: 微服务服务注册依赖于 EKS 集群 DNS 解析的稳定性。
* **安全性影响**: 强。隔离在私有子网内部；Kubernetes NetworkPolicies 将入站流量严格限制在微服务 Namespace。
* **可用性影响**: 高。跨 3 可用区分布的 3 节点 Nacos Raft 集群。

### 方案 2: 专有 EC2 集群部署 Nacos
* **描述**: 在通过 Ansible 管理的独立 3 节点 EC2 集群上部署 Nacos。
* **优势**: 将服务发现控制平面与 EKS 集群重新调度完全解耦。
* **劣势**: 较高的月度 AWS EC2 实例成本；手动 OS 补丁更新与节点维护。
* **成本影响**: 显著偏高（每个环境 3 个专有 EC2 实例）。

### 方案 3: 替代托管配置方案 (AWS AppConfig + CoreDNS)
* **描述**: 完全替代 Nacos，使用 AWS AppConfig 进行动态配置，使用 CoreDNS 进行服务发现。
* **优势**: AWS 托管的 Serverless 配置服务。
* **劣势**: 违反需求 `FUN-009`；需要重构所有约 40 个微服务的 SDK 集成。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: EKS 上部署 Nacos | 方案 2: 专有 EC2 | 方案 3: AWS AppConfig |
| :--- | :--- | :--- | :--- |
| **需求合规 (`FUN-009`)** | **100% 合规** | **100% 合规** | 不合规 |
| **延迟 & 集群内连接** | **亚毫秒级** | 中等 | 中等 |
| **成本效益 (`CST-001`)** | **高** | 低 (专有 EC2) | 中等 |
| **运维人力** | 低 | 高 | 极低 |
| **可逆性** | **易于撤销** | 可逆 | 困难 |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 1: EKS 私有应用子网中部署 Nacos 集群架构**。

---

## 7. 决策依据 (Rationale)
方案 1 在无需重构应用代码的前提下满足了功能需求 `FUN-009`，为集群内部微服务提供了亚毫秒级的延迟，并避免了专有 EC2 实例的不必要成本。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 100% 满足功能需求；最低的运维成本；原生的 EKS Pod 网络性能。
* **负面影响**: 配置持久化依赖于 MySQL 数据库层。
* **新增运维职责**: 监控 Nacos Raft 集群健康度与数据库连接池。
* **新增风险**: `RSK-ARC-002` (节点重启期间的 Raft Leader 选举延迟风险)。
* **成本影响**: 零额外基础设施开销（使用现有 EKS Worker 容量）。

---

## 9. 验证凭证 (Validation Evidence)
* Nacos 集群多可用区部署测试及跨 Namespace DNS 解析验证。

## 10. 验收条件 (Acceptance Conditions)
* 应用架构主工程师与 DevOps 负责人签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* 在 Nacos Raft 同步期间发现严重的 Pod 间延迟。

## 12. 实施影响 (Implementation Implications)
* Nacos Helm Chart / K8s Manifests 将在阶段 3 部署至 EKS 私有应用子网。
