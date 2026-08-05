# 灾难恢复 (DR) 演练与验证规划说明书 (Disaster Recovery Validation: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **灾难恢复 (DR) 区域故障转移验证规范 (Disaster Recovery Regional Failover Validation Specification)**。

根据需求 [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md) 及 [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)：
* DR 演练模拟主 AWS 区域（如 `us-east-1`）发生的完全灾难性停机。
* **严禁预先将测试结果标记为通过**。在业务 RTO/RPO SLA 目标完成签署 (`OPEN-003`) 之前，所有的 DR 验证检查项目前均处于 `暂缓 (Deferred)` 状态。

---

## 2. 灾难恢复验证矩阵 (Disaster Recovery Validation Matrix)

| DR 组件范围 | 治理需求 / ADR | 目标恢复 SLA | 目标通过验证标准 | 强制性凭证 ID | 负责角色 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 目标恢复时间 (RTO)** | [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **RTO < 4 小时** | 完整的备用区域平台在 < 4h 内上线并承接流量 | `EVD-DR-001` | 云架构主工程师 | `暂缓 (待 SLA)` |
| **2. 目标恢复点 (RPO)** | [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **RPO < 15 分钟** | 验证跨区域数据丢失窗口 < 15 分钟 | `EVD-DR-001` | DBA Lead / SRE Lead | `暂缓 (待 SLA)` |
| **3. Cloudflare 全球流量管理 (GTM) / DNS 故障转移** | [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **DNS 故障转移 < 5 分钟** | Cloudflare DNS/GTM 健康检查触发 CNAME 切换至备用 ALB | `EVD-DR-002` | 网络 Lead | `暂缓 (待 SLA)` |
| **4. 备用 EKS 集群就绪**| [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **Pilot Light / 热备** | EKS 集群控制平面在备用 AWS 区域处于活动状态 | `EVD-DR-003` | 基础设施 Lead | `暂缓 (待 SLA)` |
| **5. 跨区域数据库副本** | [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **跨区域快照** | 多区域只读副本 / 快照复制处于活动状态 | `EVD-DR-004` | DBA Lead | `暂缓 (待 SLA)` |

---

## 3. 区域灾难恢复故障转移测试协议 (Regional DR Failover Test Protocol)

### 测试 DR-01 — 区域级停机与故障转移模拟测试
* **步骤**:
  1. 在 Cloudflare DNS / GTM 中触发模拟的主 AWS 区域 (`us-east-1`) 完全停机。
  2. 将备用区域 (`us-west-2`) 中的跨区域数据库只读副本提升为主节点。
  3. 通过 Terraform / Karpenter 扩容备用 EKS Pilot Light 工作节点组。
  4. 使用备用区域中的 ArgoCD GitOps 引擎同步微服务部署。
* **通过标准**:
  1. 备用区域平台在 < 4 小时内达到 100% 可运营状态 (RTO)。
  2. 主备数据库层之间的数据丢失间隔经验证 < 15 分钟 (RPO)。
  3. 凭证日志附为 `EVD-DR-001`。
