# 阶段 0 架构阶段验收标准 (Phase 0 Acceptance Criteria)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) **阶段 0 (架构规范与需求基线)** 可衡量的验收标准 (Acceptance Criteria - AC)。

根据治理规则，这些标准评估的是**架构文档与治理框架**的完整性、严密性及可追溯性，而非最终运行中的云基础设施部署。

---

## 2. 阶段 0 验收标准矩阵 (Acceptance Criteria Matrix)

### 类别 1: 需求规范化与可追溯性
* **`AC-001` - 完整 ID 分配**: 100% 的功能、非功能、安全、运维与成本需求在 [`REQUIREMENTS-REGISTER.md`](REQUIREMENTS-REGISTER.md) 中均被分配了标准化 ID (`BUS-xxx`, `FUN-xxx`, `NFR-xxx`, `SEC-xxx`, `OPS-xxx`, `CST-xxx`)。
* **`AC-002` - 强制性元数据字段**: 每个需求条目必须明确包含需求来源、状态、优先级、验证方法及相关风险/依赖关系。
* **`AC-003` - 显式 `TBD` 标记**: 所有未验证的数值指标（如 CPU, 内存, RPS, RTO/RPO）必须显式标记为 `TBD`，并附有解决该指标所需实证数据的书面说明。

---

### 类别 2: 治理与运维规则
* **`AC-004` - AI Agent 规则定义**: 规范 AI 编码 Agent 的运维规则（包括禁止行为，如阶段 0 零 IaC 代码生成、禁止破坏性 AWS 命令）在 [`AGENTS.md`](../../AGENTS.md) 中正式发布。
* **`AC-005` - 项目治理宪章**: 业务目标、范围边界、利益相关者矩阵、交付原则及 KPI 在 [`PROJECT-CHARTER.md`](../00-governance/PROJECT-CHARTER.md) 中正式记录。
* **`AC-006` - 人工门禁强制执行**: 针对 ADR 批准、成本模型接受和 IaC 原型设计转换，建立显式的人工签署门禁。

---

### 类别 3: 假设与开放问题管理
* **`AC-007` - 工程假设登记册**: 所有临时架构假设（容器化就绪、EKS 多 AZ、AWS 账号隔离、临时默认容量规格）均在 [`ASSUMPTIONS-REGISTER.md`](ASSUMPTIONS-REGISTER.md) 中记录并附有验证方法。
* **`AC-008` - 重大影响开放问题登记册**: 在 [`OPEN-QUESTIONS.md`](OPEN-QUESTIONS.md) 中对影响 EKS 选型、中间件选型（托管 vs EKS Operator）及 DR 策略的关键架构与财务问题排定优先级。

---

### 类别 4: 架构边界与权衡清晰度
* **`AC-009` - 环境隔离需求**: 明确规定测试工作负载与生产工作负载在 AWS 账号层级实施独立隔离，禁止单集群 Namespace 混部，除非获得安全部门书面授权。
* **`AC-010` - 解耦的韧性定义**: 记录以下概念之间的清晰运维解耦：
  * 高可用 (HA - 多可用区冗余)。
  * 备份 (时间点状态快照与保留策略)。
  * 灾难恢复 (DR - 具有 RTO/RPO 目标的跨区域故障转移)。
* **`AC-011` - 多层级扩展细分**: 在 [`NON-FUNCTIONAL-REQUIREMENTS.md`](NON-FUNCTIONAL-REQUIREMENTS.md) 中对 Kubernetes Pod 扩展 (HPA/KEDA)、Node 扩展 (Karpenter) 和数据库扩展 (只读副本/分片) 进行显式架构解耦。
* **`AC-012` - 开放中间件权衡**: 确认 AWS 托管服务 (RDS, ElastiCache, MSK) vs. EKS 自建 Operator 仍保持未决状态，有待阶段 1 ADR 进行权衡评估。

---

### 类别 5: FinOps 成本建模基线
* **`AC-013` - 参数化成本估算结构**: 建立框架，一旦提供工作负载容量数据，即可计算包含计算、存储、带宽及中间件层级的 AWS 总支出。

---

## 3. 阶段转换签署检查清单 (Phase Transition Sign-Off Checklist)

| 验证项目 | 需求 / 标准 | 状态 | 签署日期 | 主审查员 |
| :--- | :--- | :--- | :--- | :--- |
| **需求完整性** | `AC-001`, `AC-002`, `AC-003` | **已验证 (VERIFIED)** | 2026-08-03 | 主架构师 (Lead Architect) |
| **治理与 Agent 规则** | `AC-004`, `AC-005`, `AC-006` | **已验证 (VERIFIED)** | 2026-08-03 | 项目发起人 (Project Sponsor) |
| **假设与开放问题日志** | `AC-007`, `AC-008` | **已验证 (VERIFIED)** | 2026-08-03 | DevOps 负责人 (DevOps Lead) |
| **架构边界** | `AC-009`, `AC-010`, `AC-011`, `AC-012` | **已验证 (VERIFIED)** | 2026-08-03 | 安全与云架构师 (Security Architect) |
| **FinOps 模型基线** | `AC-013` | **已验证 (VERIFIED)** | 2026-08-03 | FinOps 负责人 (FinOps Lead) |

> **阶段转换批准**: 在上述检查清单完全验证通过后，项目正式从 **阶段 0 (规范基线)** 转换至 **阶段 1 (高层架构设计与 ADR 撰写)**。
