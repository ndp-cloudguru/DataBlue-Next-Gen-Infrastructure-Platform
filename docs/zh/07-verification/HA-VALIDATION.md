# 高可用性与容错验证规划说明书 (High Availability Validation: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **高可用性 (HA) 与容错验证规划 (High Availability & Fault Tolerance Validation Plan)**。

根据需求 [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)：
* 高可用性保证通过模拟节点崩溃、Pod 驱逐及可用区网络停机进行验证。
* **严禁预先将测试结果标记为通过**。所有的高可用验证检查项目前均处于 `待定 (Pending)` 状态。

---

## 2. 高可用性验证矩阵 (High Availability Validation Matrix)

| HA 层级 | 治理需求 / ADR | 验证审计范围 | 目标通过验收标准 | 强制性凭证 ID | 负责角色 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 控制平面 HA** | [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | AWS EKS 托管控制平面多 AZ etcd Quorum 仲裁 | 单可用区停机期间 EKS API Server 保持可用 | `EVD-HA-001` | 云架构师 | `待定 (Pending)` |
| **2. 工作节点 HA** | [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | 跨 3 个可用区分布的 EC2 工作节点 | 节点池在 AZ-a, AZ-b, AZ-c 均衡分布 | `EVD-HA-001` | SRE Lead | `待定 (Pending)` |
| **3. Pod 拓扑分布**| [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md) | Pod 拓扑分布约束 (`topologyKey`) | 应用 Pods 均匀分布在 3 个可用区 | `EVD-HA-001` | DevOps Lead | `待定 (Pending)` |
| **4. MySQL 数据库 HA** | [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | Amazon RDS MySQL Multi-AZ 主实例终止 | 自动故障转移至备用实例 (< 60s) | `EVD-HA-002` | DBA Lead | `待定 (Pending)` |
| **5. Redis 缓存 HA** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | ElastiCache Redis 复制主节点故障转移 | 自动主节点故障转移与端点更新 (< 30s) | `EVD-HA-003` | 基础设施 Lead | `待定 (Pending)` |
| **6. RabbitMQ 代理 HA** | [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md) | RabbitMQ 3 节点 Quorum 队列 Leader 终止 | Quorum 队列 Leader 重新选举且零数据丢失 | `EVD-MQ-001` | 应用架构师 | `待定 (Pending)` |
| **7. Nacos 集群 HA** | [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md) | Nacos Raft 集群节点终止 | Raft Leader 重新选举与配置可用性 | `EVD-NC-001` | 应用架构师 | `待定 (Pending)` |

---

## 3. 高可用故障注入测试协议 (High Availability Fault Injection Protocols)

### 测试 HA-01 — 可用区黑洞模拟测试
* **步骤**: 注入 AWS 故障注入模拟器 (FIS) 网络中断，将发往和来自可用区 `AZ-a` 的所有入站/出站流量拉黑。
* **通过标准**:
  1. 位于 `AZ-b` 和 `AZ-c` 的 EKS Pod 副本处理 100% 的入站流量。
  2. ALB 健康检查在 15 秒内剔除 `AZ-a` 目标。
  3. 零面向用户的交易丢失 (`EVD-HA-001`)。

### 测试 HA-02 — Multi-AZ MySQL 主节点故障转移演练
* **步骤**: 在 RDS MySQL 主数据库实例上触发带故障转移的强制重启 (`FUN-005`)。
* **通过标准**: 备用可用区中的备用实例提升为主节点；CNAME DNS 端点更新；微服务 Pod 在 < 60 秒内自动重新连接 (`EVD-HA-002`)。
