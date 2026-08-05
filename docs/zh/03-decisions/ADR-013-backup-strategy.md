# ADR-013 — 平台备份与恢复架构策略 (Backup & Recovery Strategy)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 基础设施主架构师 (Lead Infrastructure Architect), 数据库管理员 (Database Administrator)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), 安全团队 (Security Team)
* **关联需求**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-DAT-002` (未实测的备份恢复失败风险), `RSK-SEC-003` (勒索软件备份破坏风险)
* **关联假设**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 12 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `NFR-003` 规定了可恢复性机制，以保护应用状态免受意外删除、数据损坏或勒索软件攻击。高可用性 (Multi-AZ 冗余) 可防止硬件故障，但**无法防止数据损坏或意外误删除**。我们必须建立一个时间点备份策略 (Point-in-Time Backup)，该策略与 HA 和灾难恢复 (DR) 保持明确的解耦。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **时间点恢复 (PITR)**: 能够将关系型和文档数据库恢复到 30 天保留窗口内的任何具体秒数 (`NFR-003`)。
2. **Kubernetes 集群状态捕获**: 备份自定义资源定义 (CRDs)、Secrets、ConfigMaps 及持久化卷 (`OPS-002`)。
3. **跨账号勒索软件防护**: 将不可变的备份快照复制到隔离的安全 AWS 账号中 (`SEC-002`)。

---

## 3. 约束条件 (Constraints)
* 备份必须自动运行，且不会导致数据库性能下降。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: 仅服务原生备份 (独立的数据库 Dump 脚本)
* **描述**: 运行自定义 Cron 脚本（如 `mysqldump`, `mongodump`），在 Pod 或 EC2 节点内部执行，将 Dump 文件写入本地磁盘或 S3。
* **优势**: 简单的脚本配置。
* **劣势**: Dump 执行期间极高的 CPU/内存性能冲击；缺乏时间点恢复精度；脚本故障及丢失 Kubernetes 状态的风险极高。
* **相关风险**: `RSK-DAT-002` (不一致的数据库快照和损坏的备份)。

### 方案 2: 纯 AWS Backup 服务
* **描述**: 利用集中式 AWS Backup 策略为 AWS RDS、EBS 卷和 S3 Bucket 创建快照。
* **优势**: 单一集中式 AWS 备份 Dashboard；自动化的 AWS Backup Vault Lock（勒索软件防护）；跨账号复制支持。
* **劣势**: 无法原生捕获 Kubernetes 应用 Manifests、CRDs 或集群内部 StatefulSet 卷声明。

### 方案 3: 混合备份模型 (原生数据库 PITR + Velero EKS 状态备份) — 推荐方案
* **描述**: 包含两个部分的全面备份架构：
  1. **数据库层**: 自动化每日托管快照，结合持续的交易日志，为 MySQL、MongoDB 和 Redis 实现 30 天时间点恢复 (PITR) (`NFR-003`)。
  2. **Kubernetes 层**: 在 EKS 中安装 Velero Backup Operator，安排集群 CRDs、Namespaces、Secrets 及 EBS 卷快照每日自动备份并加密直接写入 S3 Bucket (`OPS-002`)。
  3. **跨账号勒索软件隔离**: 自动将 S3 备份快照复制到独立的安全 AWS 账号中 (`SEC-002`)。
* **优势**: 100% 覆盖数据库状态和 Kubernetes 运维 Manifests；零数据库表锁；不可变的勒索软件防护；快速的全集群恢复。
* **劣势**: 需要维护 Velero Operator CRD 和 S3 Bucket IAM 策略。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: Dump 脚本 | 方案 2: 纯 AWS Backup | 方案 3: 混合备份 (原生 DB + Velero) |
| :--- | :--- | :--- | :--- |
| **时间点恢复 (PITR)** | 弱 | 强 | **强 (秒级精准恢复)** |
| **K8s 状态捕获 (`OPS-002`)** | 不存在 | 弱 | **强 (Velero CRDs)** |
| **勒索软件隔离 (`SEC-002`)** | 弱 | 强 | **强 (跨账号 S3 复制)** |
| **运维可靠性** | 低 | 高 | **高 (High)** |
| **可逆性** | 困难 | 可逆 | **易于撤销 (Easily Reversible)** |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 3: 混合备份模型** (原生数据库 PITR 快照 + Velero EKS 状态备份至 S3)。

---

## 7. 决策依据 (Rationale)
方案 3 为数据库交易状态和 Kubernetes 配置 Manifests 提供了绝对的可恢复性 (`NFR-003`)，同时强制执行跨账号不可变 S3 备份副本隔离，即便环境账号受到攻击也能确保完全恢复。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 完整的 30 天 PITR 数据库恢复；通过 Velero 实现自动化的 Kubernetes 集群状态恢复；防勒索软件的跨账号备份副本。
* **负面影响**: 需要配置 Velero S3 Bucket 复制策略。
* **新增运维职责**: 执行每季度自动化的备份恢复演练 (`RSK-DAT-002`)。
* **成本影响**: 标称的 S3 快照存储开销。

---

## 9. 验证凭证 (Validation Evidence)
* Velero 集群恢复演练与数据库时间点快照恢复校验。

## 10. 验收条件 (Acceptance Conditions)
* 基础设施 Lead 与安全团队签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* 出现要求多年离线磁带备份合规的监管指令。

## 12. 实施影响 (Implementation Implications)
* Velero Helm Chart 和 AWS Backup 生命周期策略将于阶段 3 部署。
