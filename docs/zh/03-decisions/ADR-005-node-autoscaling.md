# ADR-005 — 节点级自动扩缩容引擎策略 (Node Autoscaling Engine)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 云架构主工程师 (Lead Cloud Architect), 基础设施工程师 (Infrastructure Engineer)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), FinOps 团队 (FinOps Team)
* **关联需求**: [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-SCL-001` (节点拉起延迟过高), `RSK-CST-001` (不受控的节点自动扩缩容成本)
* **关联假设**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 10 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `NFR-002` 规定了托管约 40 个微服务的 EKS 集群需要进行动态的节点级基础设施扩缩容。容量指标目前不可用 (`OPEN-001`)。我们必须选择一个能够在无需人工容量管理的情况下、根据 Pod 调度需求动态匹配节点容量的自动扩缩容引擎。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **拉起延迟 (Provisioning Latency)**: 当存在未调度的待处理 Pod 时，快速响应并扩容节点容量 (`NFR-002`)。
2. **成本优化与资源合理化 (Rightsizing)**: 选择精准匹配待处理 Pod 资源 Request 的 EC2 实例规格与类型，避免节点装箱浪费 (`CST-001`)。
3. **运维简易度**: 消除为不同 CPU/RAM 实例层级手动预定义 EC2 Auto Scaling Groups (ASGs) 的开销。

---

## 3. 约束条件 (Constraints)
* 必须在 Amazon EKS 内部原生运行。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: 静态 EC2 节点容量 (无自动扩缩容)
* **描述**: 根据估算的峰值负载为每个 Node Group 预置固定数量的 EC2 实例。
* **优势**: 配置简单；零自动扩缩容逻辑 Bug。
* **劣势**: 非高峰流量期间严重的成本过度消费；突发流量激增时存在集群内存不足 (OOM) 崩溃的风险。
* **安全性影响**: 中性。
* **可用性影响**: 流量激增期间较弱。
* **可扩展性影响**: 零动态节点扩缩容 (`NFR-002` 违规)。
* **运维影响**: 需要 SRE 人工干预来调整 EC2 实例数量。
* **成本影响**: 极其低效（每月高额 AWS 资源浪费）。

### 方案 2: 托管 Node Groups 配合 Kubernetes Cluster Autoscaler (CAS)
* **描述**: 使用标准的 Kubernetes Cluster Autoscaler，监控待处理 Pod 并增加 AWS Auto Scaling Groups (ASGs) 的期望容量。
* **优势**: 经受过实战检验的 Kubernetes 标准方案；由 EKS Managed Node Groups 原生支持。
* **劣势**: 扩容响应较慢 (每个节点约 ~3-5 分钟)；受限于预先配置的固定 ASG 实例类型；对多样化 Pod 尺寸的装箱效率低下。
* **安全性影响**: 良好。集成了 AWS IAM IRSA。
* **可用性影响**: 中等至高。
* **可扩展性影响**: 中等。受限于预定义的 ASG Node Pool。

### 方案 3: EKS 托管 Node Groups + Karpenter (JIT 即时扩缩容引擎) — 推荐方案
* **描述**: 部署 Karpenter，这是由 AWS 构建的开源、高性能 Kubernetes 节点自动扩缩容引擎，无需底层 ASG 即可直接创建 EC2 实例。
* **优势**: 极速拉起 (< 1 分钟节点启动)；根据精确的 Pod 需求动态选择匹配的实例系列 (`c6i`, `m6i`, `r6i`)；自动节点合并与碎片整理 (`CST-001`)；测试环境无缝的 Spot 实例编排。
* **劣势**: 需要配置 Karpenter Controller 生命周期与 NodePool CRD。
* **安全性影响**: 强。使用 AWS IAM Roles for Service Accounts (IRSA)。
* **可用性影响**: 极佳。根据拓扑约束自动进行多可用区 (Multi-AZ) 节点创建。
* **可扩展性影响**: 极佳。直接调用 EC2 Fleet API 扩容，绕过 ASG 瓶颈。
* **运维影响**: 消除了 ASG 维护；需要掌握 Karpenter NodePool CRD 配置。
* **成本影响**: 最高的成本效益（通过智能装箱整理，削减 15-30% 的计算浪费）。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: 静态 EC2 | 方案 2: Cluster Autoscaler (CAS) | 方案 3: Karpenter (JIT) |
| :--- | :--- | :--- | :--- |
| **拉起速度** | 无 | 中等 (~3-5 分钟) | **极速 (< 1 分钟)** |
| **装箱整理效率** | 弱 | 中等 | **强 (Strong)** |
| **ASG 维护开销** | 人工 | 高 (多个 ASG) | **零 ASG 维护开销** |
| **成本优化 (`CST-001`)** | 弱 | 中等 | **强 (Strong)** |
| **可逆性** | 易于撤销 | 可逆 | **可逆 (Reversible)** |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 3: EKS 托管 Node Groups + Karpenter (JIT 即时扩缩容引擎)**。

---

## 7. 决策依据 (Rationale)
Karpenter 提供了卓越的拉起速度 (`NFR-002`)，在无需 ASG 开销的情况下实现了动态实例自动选择，并在工作负载容量参数尚未完全确认时提供了最佳的 FinOps 碎片整理成本节约 (`CST-001`)。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 快速的节点拉起；自动化的节点合并碎片整理；零 ASG 管理开销。
* **负面影响**: 团队必须管理 Karpenter NodePool CRD 配置。
* **新增运维职责**: 监控 Karpenter Controller 日志及实例中断事件队列。
* **新增风险**: `RSK-CST-001` (若省略 Pod 资源 Limit 设置，可能导致不受控的节点扩缩容消费)。
* **成本影响**: 通过智能合理化配置，显著降低 EC2 月度计算支出。

---

## 9. 验证凭证 (Validation Evidence)
* Karpenter 节点拉起延迟基准测试及 Pod 重新调度合并测试。

## 10. 验收条件 (Acceptance Conditions)
* 基础设施 Lead 与 FinOps 团队签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* Karpenter Controller 与未来 EKS API 版本出现不兼容。

## 12. 实施影响 (Implementation Implications)
* Karpenter Helm Chart 及 NodePool CRD Manifests 将在阶段 3 进行部署。
