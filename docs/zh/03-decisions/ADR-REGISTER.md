# ADR 决策记录主索引 (Master ADR Register: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档作为 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 所有 **架构决策记录 (ADR)** 的 Master 索引登记册。

根据阶段 3 治理规则：
* 所有 ADR 目前处于 **`待审查 (Proposed)`** 或 **`暂缓/待定 (Deferred)`** 状态。
* 未经正式的人工书面签署，任何决策均不会标记为 `已接受 (Accepted)`。

---

## 2. ADR 主索引登记表 (ADR Master Registry)

| ADR ID | 决策主题 | 状态 | 核心需求 | 主要风险 | 决策依赖 | 所需验证凭证 | 目标审查阶段 | 最后更新 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| [`ADR-001`](ADR-001-aws-account-strategy.md) | AWS 账号架构策略 | `待审查` | `BUS-003`, `SEC-002` | `RSK-SEC-003` | 无 | AWS Landing Zone 蓝图审查 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-002`](ADR-002-environment-isolation.md) | 环境隔离架构模型 | `待审查` | `BUS-003`, `SEC-002`, `NFR-001` | `RSK-SEC-003` | `ADR-001` | EKS 多账号安全审计 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-003`](ADR-003-kubernetes-platform.md) | Kubernetes 容器编排平台选型 | `待审查` | `BUS-001`, `FUN-001`, `OPS-001` | `RSK-OPS-001` | `ADR-001`, `ADR-002` | EKS 控制平面 SLA 签署 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-004`](ADR-004-cicd-operating-model.md) | CI/CD 运维与工具链模式 | `待审查` | `BUS-002`, `FUN-002`–`FUN-004` | `RSK-SEC-001`, `RSK-ARC-001` | `ADR-001`, `ADR-011` | Jenkins-Ansible 流水线接口 Dry-Run 预检 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-005`](ADR-005-node-autoscaling.md) | 节点级自动扩缩容引擎策略 | `待审查` | `NFR-002`, `CST-001` | `RSK-UNC-001`, `RSK-SCL-001` | `ADR-003` | Karpenter 节点拉起延迟基准测试 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-006`](ADR-006-mysql-deployment.md) | MySQL 数据库部署架构策略 | `暂缓/待定` | `FUN-005`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | 微服务数据库 IOPS 与容量指标 | 阶段 1 / 阶段 2 | 2026-08-03 |
| [`ADR-007`](ADR-007-redis-deployment.md) | Redis 缓存集群部署架构策略 | `暂缓/待定` | `FUN-008`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | 缓存内存占用与 IOPS 剖析 | 阶段 1 / 阶段 2 | 2026-08-03 |
| [`ADR-008`](ADR-008-rabbitmq-deployment.md) | RabbitMQ 消息代理部署架构策略 | `暂缓/待定` | `FUN-006`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | 消息吞吐量与队列深度指标 | 阶段 1 / 阶段 2 | 2026-08-03 |
| [`ADR-009`](ADR-009-mongodb-deployment.md) | MongoDB 文档数据库部署架构策略 | `暂缓/待定` | `FUN-007`, `CST-001` | `RSK-DAT-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | MongoDB 查询/驱动与 DocumentDB 兼容性审计 | 阶段 1 / 阶段 2 | 2026-08-03 |
| [`ADR-010`](ADR-010-nacos-deployment.md) | Nacos 服务注册与配置中心部署架构策略 | `待审查` | `FUN-009`, `OPS-001` | `RSK-ARC-002` | `ADR-003` | Nacos 跨 Namespace DNS 解析测试 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-011`](ADR-011-secrets-management.md) | 密钥与敏感信息管理架构拓扑 | `待审查` | `SEC-001`, `FUN-002`–`FUN-004` | `RSK-SEC-001`, `RSK-SEC-002` | `ADR-001`, `ADR-003` | External Secrets Operator 同步测试 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-012`](ADR-012-observability.md) | 全栈可观测性架构方案 | `待审查` | `OPS-001`, `OPS-002` | `RSK-CST-002`, `RSK-OPS-002` | `ADR-001`, `ADR-003` | Fluent Bit 日志转发基准测试 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-013`](ADR-013-backup-strategy.md) | 平台备份与恢复架构策略 | `待审查` | `NFR-003`, `OPS-002` | `RSK-DAT-002` | `ADR-006`–`ADR-010` | 自动化数据库与 Velero 恢复测试 | 阶段 3 / 阶段 1 | 2026-08-03 |
| [`ADR-014`](ADR-014-disaster-recovery.md) | 灾难恢复 (DR) 架构策略 | `暂缓/待定` | `NFR-003`, `CST-001` | `RSK-UNC-003`, `RSK-AVL-001` | `ADR-001`, `ADR-013` | 业务系统 RTO/RPO 目标签署 | 阶段 1 / 阶段 2 | 2026-08-03 |
| [`ADR-015`](ADR-015-infrastructure-as-code.md) | 基础设施即代码 (IaC) 架构选型方案 | `待审查` | `BUS-002`, `AGENTS.md` | `RSK-DEL-001` | `ADR-001` | Terraform 模块语法检查与 Dry-Run 预检审计 | 阶段 3 / 阶段 1 | 2026-08-03 |
