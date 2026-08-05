# ADR-006 — MySQL 数据库部署架构策略 (MySQL Deployment Strategy)

## 元数据 (Metadata)
* **状态**: `暂缓/待定 (Deferred)`
* **日期**: 2026-08-03
* **决策负责人**: 数据架构主工程师 (Lead Data Architect), 云基础设施 Lead (Cloud Infrastructure Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), FinOps 团队 (FinOps Team)
* **关联需求**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-UNC-001` (缺少数据库工作负载指标), `RSK-OPS-001` (自建数据库运维负担), `RSK-CST-001` (托管数据库成本激增)
* **关联假设**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 3 节, 第 6 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `FUN-005` 规定需要高可用的 MySQL 关系型数据库服务，用于应用数据的持久化存储。我们必须确定 MySQL 的部署拓扑结构（EKS 自建 vs. Amazon RDS for MySQL vs. Amazon Aurora MySQL）。目前尚缺少数据库工作负载指标（DB 容量大小、IOPS、并发连接数、读写比例）(`OPEN-001`)。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **高可用性与自动化故障转移**: 跨可用区 (Multi-AZ) 的同步/异步复制，实现零数据丢失目标 (`NFR-001`)。
2. **运维与备份负担**: 自动化补丁更新、时间点恢复 (PITR) 以及存储自动扩展 (`NFR-003`)。
3. **总体拥有成本 (TCO)**: 综合评估软件许可、云基础设施定价以及持续的 DBA 运维人力开销 (`CST-001`)。
4. **数据厂商绑定与可移植性**: 在多云或本地环境间自由迁移数据库状态的能力。

---

## 3. 约束条件 (Constraints)
* 必须原生支持标准 MySQL 8.0+ 传输协议。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: EKS 自建 MySQL Operator (如 Bitnami / KubeBlocks Operator)
* **描述**: 使用基于 EBS 持久卷 (`gp3`) 的 Kubernetes Operator 在 EKS 内部部署 MySQL 主从复制集群。
* **优势**: 消除了 AWS 托管数据库溢价开销；拥有对 MySQL 配置参数的完全管理权限；具备极高的云可移植性。
* **劣势**: 高度的运维复杂度；团队必须自行管理有状态卷故障转移、手动复制修复、EBS 快照生命周期及 DBA 补丁更新。
* **安全性影响**: 中等。安全加固与 KMS 卷加密由团队自行管理。
* **可用性影响**: 中等。受限于 Kubernetes Pod 重新调度延迟和可用区停机期间的 EBS 卷重新挂载延迟（~2-5 分钟）。
* **可扩展性影响**: 手动读写分离 Pod 扩容及 EBS 卷手动扩容。
* **运维影响**: 沉重的日常 DBA 与 SRE 人力负担 (`RSK-OPS-001`)。
* **成本影响**: 较低的 AWS 基础设施成本，但持续的人力维护成本极高。
* **厂商绑定**: 极低。
* **相关风险**: `RSK-OPS-001` (节点崩溃期间的数据库卷损坏或复制失败风险)。

### 方案 2: Amazon RDS for MySQL (Multi-AZ) — 推荐基线
* **描述**: 创建完全托管的 Amazon RDS MySQL 实例，跨 2-3 个可用区部署，支持自动故障转移。
* **优势**: 剥离了 95% 的 DBA 运维工作；自动化 Multi-AZ 故障转移 (< 60 秒)；自动化每日备份与 PITR；托管的安全补丁更新。
* **劣势**: 相比原生 EC2/EKS 计算资源，AWS 小时实例单价较高。
* **安全性影响**: 极佳。原生 AWS KMS 加密、IAM 数据库身份验证、VPC 子网隔离。
* **可用性影响**: 强。AWS 承诺 99.95% 在线率 SLA。
* **可扩展性影响**: 轻松的垂直实例扩容及只读副本 (Read-Replica) 终端添加。
* **运维影响**: DevOps 团队仅需极少的运维维护。
* **成本影响**: 中等至偏高的 AWS 月度支出。

### 方案 3: Amazon Aurora MySQL 兼容版
* **描述**: AWS 专有的云原生关系型数据库引擎，存储层跨 3 个可用区自动进行 6 份副本复制。
* **优势**: 极其卓越的性能（最高达标准 MySQL 5 倍吞吐）；高达 128TB 的存储自动扩展；近乎瞬时的崩溃恢复 (< 30 秒)。
* **劣势**: 显著偏高的基础成本；专有 AWS 存储引擎层。
* **安全性影响**: 极佳。
* **可用性影响**: 极佳 (99.99% SLA)。
* **成本影响**: 成本最高选项（比标准 RDS 高 20-40% 溢价）。
* **厂商绑定**: 高 (Aurora 存储架构绑定)。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: EKS 自建 Operator | 方案 2: Amazon RDS MySQL | 方案 3: Amazon Aurora MySQL |
| :--- | :--- | :--- | :--- |
| **可用性 & SLA (`NFR-001`)** | 中等 | **强 (99.95%)** | **强 (99.99%)** |
| **运维人力开销** | 沉重 | **极低** | **极低** |
| **性能上限** | 中等 | 中-高 | **高 (High)** |
| **成本效益 (`CST-001`)** | 高基础设施 / 高人力 | **平衡 (Balanced)** | 低 (高 AWS 溢价) |
| **厂商绑定** | **极低** | 中等 | 高 |

---

## 6. 提议决策 (Proposed Decision)
**暂缓/待定决策 (Decision Deferred)**。

---

## 7. 决策依据 (Rationale)
在缺少实测数据库工作负载剖析数据 (`OPEN-001`) 的情况下，**无法在防守性上做出最终的架构选择**。

在缺少容量数据时盲目选择方案 2 存在预算超支风险；在缺少 DBA 团队指标时选择方案 1 存在运维失败风险。

---

## 8. 签署前所需的验证凭证
1. 微服务 MySQL 数据库数据容量大小、交易 RPS、读写比例及连接池需求 (`OPEN-001`)。
2. DBA 运维能力与响应 SLA 签署。
3. FinOps 月度预算分配审查。

## 9. 验收条件 (Acceptance Conditions)
* 提交验证通过的客户数据库工作负载指标并完成正式架构委员会审查。

## 10. 重新评估触发条件 (Revisit Triggers)
* 阶段 1 工作负载剖析完成。

## 11. 实施影响 (Implementation Implications)
* 架构设计在 IaC 中保持抽象的数据库子网隔离，直至阶段 1 完成决策签署。
