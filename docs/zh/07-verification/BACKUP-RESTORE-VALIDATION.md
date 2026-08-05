# 备份与恢复验证规划说明书 (Backup & Restore Validation: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **备份与时间点恢复 (PITR) 验证规范 (Backup & PITR Validation Specification)**。

根据需求 [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md) 及 [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)：
* 备份独立于高可用性 (HA) 运行，以防止数据损坏或意外误删除。
* 每月执行恢复演练，验证时间点恢复至隔离的测试子网。
* **严禁预先将测试结果标记为通过**。所有的备份验证检查项目前均处于 `待定 (Pending)` 状态。

---

## 2. 备份与恢复验证矩阵 (Backup & Restore Validation Matrix)

| 目标状态领域 | 治理需求 / ADR | 备份生命周期策略 | 目标通过恢复标准 | 强制性凭证 ID | 负责角色 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 关系型数据库 (MySQL)**| [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | 每日自动快照 + 30 天 PITR 持续交易日志 | 100% 数据库记录恢复至精确的时间戳 | `EVD-DB-001` | DBA Lead | `待定 (Pending)` |
| **2. 文档数据库 (MongoDB)** | [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | 每日卷快照 + oplog 持续归档 (30 天 PITR) | 完整重放 oplog 至目标恢复秒数 | `EVD-DB-002` | DBA Lead | `待定 (Pending)` |
| **3. 内存级缓存 (Redis)** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | 每日 RDB 快照导出至加密 S3 Bucket | Redis RDB 快照恢复至新节点 (< 15m) | `EVD-CACHE-002` | 基础设施 Lead | `待定 (Pending)` |
| **4. EKS Kubernetes 集群状态**| [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Velero 每日备份 CRDs, Manifests 与 PVC 卷快照 | 完整集群 Manifests 与卷恢复至测试 EKS | `EVD-BK-001` | SRE Lead | `待定 (Pending)` |
| **5. 跨账号备份副本** | [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | 自动复制至隔离的安全 AWS 账号 | 在安全账号中验证不可变的备份副本 | `EVD-BK-002` | 云安全 Lead | `待定 (Pending)` |
| **6. 勒索软件防护** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | 合规模式下的 AWS Backup Vault Lock | 零保留策略覆写或提前删除 | `EVD-BK-003` | 云安全 Lead | `待定 (Pending)` |

---

## 3. 恢复测试步骤 (Restore Test Procedures)

### 测试 BAK-01 — MySQL 时间点恢复 (PITR) 演练
* **步骤**:
  1. 向 `DataBlue-Prod-Account` MySQL 数据库中插入打有时间戳的测试记录。
  2. 模拟在时间戳 `T_drop` 发生的意外数据库表清空。
  3. 发起 AWS RDS PITR 恢复至目标时间戳 `T_drop - 1 秒`，目标位置为隔离的测试 VPC 数据库子网。
* **通过标准**: `T_drop` 之前的 100% 数据记录成功恢复；验证零交易丢失 (`EVD-DB-001`)。

### 测试 BAK-02 — Velero 集群状态恢复演练
* **步骤**: 将 `velero restore create --from-backup prod-daily-backup` 执行恢复至空测试 EKS 集群中。
* **通过标准**: 100% 的 Kubernetes Deployment Manifests、ConfigMaps、Secrets 和 EBS PersistentVolumeClaims 恢复至 `Ready` 状态 (`EVD-BK-001`)。
