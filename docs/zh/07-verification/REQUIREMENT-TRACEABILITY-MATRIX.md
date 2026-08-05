# 需求可追溯性矩阵说明书 (Requirement Traceability Matrix: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **需求可追溯性矩阵 (RTM)**。

文档将 [`REQUIREMENTS-REGISTER.md`](../01-requirements/REQUIREMENTS-REGISTER.md) 中的每一项需求 (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`) 映射到其治理架构决策 (`ADR`)、实施工作包 (`WP`)、目标验证领域文档、凭证 ID、负责人及验证状态。

---

## 2. Master 需求可追溯性矩阵 (Master Requirement Traceability Matrix)

| 需求 ID | 需求摘要 | 治理 ADR(s) | 实施工作包 (WP) | 目标验证文档 | 凭证 ID | 负责角色 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`BUS-001`** | 跨 5-6 个业务系统的约 40 个微服务 | [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | `WP-001`, `WP-005`, `WP-017` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-PRF-001` | 应用架构主工程师 | `待定 (Pending)` |
| **`BUS-002`** | 自动化应用部署 | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-007`, `WP-010` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-CICD-001` | DevOps Lead | `待定 (Pending)` |
| **`BUS-003`** | 独立测试与生产环境 | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md) | `WP-002`, `WP-005`, `WP-015` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-ENV-001` | 基础设施架构师 | `待定 (Pending)` |
| **`BUS-004`** | 详细的 AWS 成本估算 | 所有 ADRs | `WP-019` | [`COST-VALIDATION.md`](COST-VALIDATION.md) | `EVD-CST-001` | FinOps Lead | `待定 (Pending)` |
| **`FUN-001`** | Kubernetes 容器编排平台 | [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | `WP-005`, `WP-015` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-K8S-001` | 云架构师 | `待定 (Pending)` |
| **`FUN-002`** | GitLab 源码与 MR 触发集成 | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-010` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-CICD-002` | DevOps 工程师 | `待定 (Pending)` |
| **`FUN-003`** | Jenkins CI Worker 构建与镜像扫描 | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-010` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-001` | DevOps 工程师 | `待定 (Pending)` |
| **`FUN-004`** | Ansible Playbook 配置管理 | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-010` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-CICD-003` | DevOps 工程师 | `待定 (Pending)` |
| **`FUN-005`** | 关系型数据库 (MySQL) 交付 | [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | `WP-011` | [`BACKUP-RESTORE-VALIDATION.md`](BACKUP-RESTORE-VALIDATION.md) | `EVD-DB-001` | DBA Lead | `待定 (Pending)` |
| **`FUN-006`** | 消息队列代理 (RabbitMQ) 交付 | [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md) | `WP-012` | [`HA-VALIDATION.md`](HA-VALIDATION.md) | `EVD-MQ-001` | 应用架构主工程师 | `待定 (Pending)` |
| **`FUN-007`** | 文档数据库 (MongoDB) 交付 | [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md) | `WP-011` | [`BACKUP-RESTORE-VALIDATION.md`](BACKUP-RESTORE-VALIDATION.md) | `EVD-DB-002` | DBA Lead | `待定 (Pending)` |
| **`FUN-008`** | 内存级缓存层 (Redis) 交付 | [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | `WP-012` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-CACHE-001` | 基础设施架构主工程师 | `待定 (Pending)` |
| **`FUN-009`** | 服务发现与配置中心 (Nacos) | [`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md) | `WP-013` | [`HA-VALIDATION.md`](HA-VALIDATION.md) | `EVD-NC-001` | 应用架构主工程师 | `待定 (Pending)` |
| **`NFR-001`** | 高可用性与多可用区容错 | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | `WP-004`, `WP-005`, `WP-018` | [`HA-VALIDATION.md`](HA-VALIDATION.md) | `EVD-HA-001` | SRE Lead | `待定 (Pending)` |
| **`NFR-002`** | 动态自动扩缩容 (Pod 与节点) | [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | `WP-005`, `WP-014` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-SCL-001` | SRE Lead | `待定 (Pending)` |
| **`NFR-003`** | 灾难恢复与备份保留 | [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | `WP-011`, `WP-016`, `WP-018` | [`DR-VALIDATION.md`](DR-VALIDATION.md) | `EVD-DR-001` | 云架构主工程师 | `待定 (Pending)` |
| **`NFR-004`** | 性能与吞吐量 SLA 目标 | [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | `WP-014` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-PRF-002` | 性能 Lead | `待定 (Pending)` |
| **`SEC-001`** | IAM Identity Center, IRSA & RBAC 范围 | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md) | `WP-003`, `WP-009` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-002` | 云安全 Lead | `待定 (Pending)` |
| **`SEC-002`** | 账号隔离与网络边界 | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md) | `WP-002`, `WP-004` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-003` | 云安全 Lead | `待定 (Pending)` |
| **`SEC-003`** | 静态与传输中数据加密 | [`ADR-011`](../03-decisions/ADR-011-secrets-management.md) | `WP-003`, `WP-016` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-004` | 云安全 Lead | `待定 (Pending)` |
| **`OPS-001`** | 服务器与微服务指标监控 | [`ADR-012`](../03-decisions/ADR-012-observability.md) | `WP-008` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-OPS-001` | 运维 Lead | `待定 (Pending)` |
| **`OPS-002`** | 集中式日志聚合与长期归档 | [`ADR-012`](../03-decisions/ADR-012-observability.md) | `WP-008`, `WP-016` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-OPS-002` | 运维 Lead | `待定 (Pending)` |
| **`CST-001`** | 成本优化与资源合理化 | [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | `WP-019` | [`COST-VALIDATION.md`](COST-VALIDATION.md) | `EVD-CST-002` | FinOps Lead | `待定 (Pending)` |
| **`CST-002`** | 财务标签与预算治理 | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md) | `WP-002`, `WP-019` | [`COST-VALIDATION.md`](COST-VALIDATION.md) | `EVD-CST-003` | FinOps Lead | `待定 (Pending)` |
