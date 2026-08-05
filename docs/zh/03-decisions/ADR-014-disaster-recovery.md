# ADR-014 — 灾难恢复 (DR) 架构策略 (Disaster Recovery Strategy)

## 元数据 (Metadata)
* **状态**: `暂缓/待定 (Deferred)`
* **日期**: 2026-08-03
* **决策负责人**: 企业架构委员会 (Enterprise Architecture Board), 云基础设施 Lead (Cloud Infrastructure Lead)
* **审查团队**: 客户业务产品负责人 (Customer Product Owners), 安全 Lead (Security Lead)
* **关联需求**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-UNC-003` (未明确的 RTO/RPO 目标), `RSK-AVL-001` (单区域 AWS 停机依赖风险)
* **关联假设**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 13 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `NFR-003` 规定了灾难恢复 (DR) 机制，以确保在灾难性事件期间的业务连续性。**高可用性 (单区域内 Multi-AZ 冗余) 绝不能与灾难恢复 (跨区域故障转移 Cross-Region Failover) 混淆**。Multi-AZ 防止本地硬件/可用区故障，但如果发生完整的 AWS 区域级停机，平台仍将不可用 (`RSK-AVL-001`)。具体 RTO 和 RPO 指标目前尚未确认 (`OPEN-003`)。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **目标恢复时间目标 (RTO)**: 区域停机期间可接受的最大停机时长 (`NFR-003`)。
2. **目标恢复点目标 (RPO)**: 区域停机期间可接受的最大数据丢失窗口 (`NFR-003`)。
3. **AWS 基础设施成本倍增系数**: 评估跨区域复制与待命计算节点对 AWS 月度云消费的影响 (`CST-001`)。
4. **运维复杂度**: 执行自动化或手动区域 DNS 故障转移所需的运维纪律。

---

## 3. 约束条件 (Constraints)
* 在选择 DR 拓扑之前，RTO 和 RPO 目标必须获得业务产品负责人的书面正式授权。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: 仅 Multi-AZ 高可用 (单区域依赖，无 DR)
* **描述**: 严格依赖主 AWS 区域内的 3-AZ 冗余，不进行跨区域复制。
* **优势**: 成本最低（零备用区域基础设施或数据传输费）。
* **劣势**: 在完整的 AWS 区域级故障期间，整个平台彻底离线；极高的业务中断风险 (`RSK-AVL-001`)。

### 方案 2: 备份与恢复 (备用区域冷备 Cold Standby)
* **描述**: 将数据库备份和 Velero 集群 Manifests 复制到备用 AWS 区域的 S3 Bucket。发生灾难时，通过 IaC 脚本从零开始拉起新的 EKS 集群。
* **优势**: 持续成本极低（仅产生 S3 跨区域数据传输费）。
* **劣势**: RTO 较高（需要 4 至 24 小时）来拉起 EKS 控制平面、节点组并恢复数据库状态。
* **RTO / RPO 目标**: RTO = 4–24 小时；RPO < 1 小时。

### 方案 3: Pilot Light 热备策略 (备用区域最小化基础设施) — 推荐候选
* **描述**: 在备用区域拉起最小化的脚手架：数据库跨区域只读副本、预先创建的 VPC/子网、保持运行的 EKS 控制平面。发生故障转移时，EKS 节点池自动扩容拉起。
* **优势**: 极快 RTO (1 至 2 小时)；近乎零的数据丢失 (RPO < 15 分钟)。
* **劣势**: 备用 EKS 控制平面和数据库只读副本会产生中等的月度固定成本。
* **RTO / RPO 目标**: RTO = 1–2 小时；RPO < 15 分钟。

### 方案 4: Warm Standby / 跨区域 Active-Active 多主模式
* **描述**: 在备用 AWS 区域托管完全预置、按比例缩容的活动 EKS 集群及实时 Active-Active 数据库集群，配合 Cloudflare GTM 进行自动 DNS 健康检查与切流。
* **优势**: 近乎零 RTO (< 5 分钟)；近乎零 RPO (< 1 分钟)。
* **劣势**: 极其昂贵（基础基础设施成本翻倍）；高昂的跨区域数据传输费；多区域数据库状态同步极其复杂的运维难度。
* **成本影响**: 月度 AWS 支出翻倍 (2x 成本倍增)。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: 仅 Multi-AZ | 方案 2: 备份与恢复 | 方案 3: Pilot Light | 方案 4: Warm Standby |
| :--- | :--- | :--- | :--- | :--- |
| **RTO 能力** | 无 (数天) | 4–24 小时 | **1–2 小时** | < 5 分钟 |
| **RPO 能力** | 无 | < 1 小时 | **< 15 分钟** | < 1 分钟 |
| **AWS 成本倍数** | **1.0x (基线)** | **1.05x** | 1.3x | 2.0x (成本翻倍) |
| **运维人力** | **低** | 中等 | 中等 | 极度沉重 |
| **可逆性** | **易于撤销** | **易于撤销** | 可逆 | 困难 |

---

## 6. 提议决策 (Proposed Decision)
**暂缓/待定决策 (Decision Deferred)**。

---

## 7. 决策依据 (Rationale)
在缺少已记录的 RTO 和 RPO 目标的情况下选择灾难恢复策略在治理规则下是严格禁止的。

方案 2 (备份与恢复) 或方案 3 (Pilot Light) 是领先的技术候选方案，但最终选择**暂缓，有待客户利益相关者完成业务系统关键性分级及 RTO/RPO 签署** (`OPEN-003`)。

---

## 8. 签署前所需的验证凭证
1. 客户针对每个业务系统的 RTO 和 RPO 目标进行正式书面签署 (`OPEN-003`)。
2. FinOps 预算批准备用区域基础设施开支。

## 9. 验收条件 (Acceptance Conditions)
* 业务产品负责人、企业架构委员会及 FinOps 团队书面签署。

## 10. 重新评估触发条件 (Revisit Triggers)
* 阶段 1 业务连续性分类完成。

## 11. 实施影响 (Implementation Implications)
* 平台架构在阶段 3 的模块化 Terraform 中支持备用区域 Pilot Light 模块的声明。
