# FinOps 成本治理与验证规划说明书 (FinOps Cost Validation: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **FinOps 成本治理与容量验证规划 (FinOps Cost Governance & Sizing Validation Plan)**。

根据需求 [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md)、[`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md) 及 [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)：
* 实际 AWS 消费每月针对参数化成本模型 ([`COST-MODEL.md`](../05-cost/COST-MODEL.md)) 及场景 1 至 4 ([`COST-SCENARIOS.md`](../05-cost/COST-SCENARIOS.md)) 进行审计。
* **严禁预先将测试结果标记为通过**。所有的成本验证检查项目前均处于 `待定 (Pending)` 状态。

---

## 2. 成本治理验证矩阵 (Cost Governance Validation Matrix)

| FinOps 治理领域 | 治理需求 / 策略 | 审计验证范围 | 目标通过验收标准 | 强制性凭证 ID | 负责角色 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 资源标签合规** | [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | AWS Config 标签策略规则审计 | **100%** 的预置 AWS 资源包含有效标签 | `EVD-CST-001` | FinOps Lead | `待定 (Pending)` |
| **2. 消费与模型偏差** | [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-MODEL.md`](../05-cost/COST-MODEL.md) | 月度 AWS Cost Explorer 账单 vs 场景基线 | 月度 AWS 消费偏差在成本模型的 **±15%** 范围内 | `EVD-CST-002` | FinOps Lead | `待定 (Pending)` |
| **3. 非生产自动缩容**| [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | 定时在测试 EKS 工作节点上执行缩容 | 非工作时间（夜间/周末）节点数量下调 70% | `EVD-CST-003` | SRE Lead | `待定 (Pending)` |
| **4. Spot 实例利用率** | [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | 测试 EKS 工作节点实例计费类型组合 | 测试环境中 EC2 Spot 实例占比 **≥ 70%** | `EVD-CST-004` | 基础设施 Lead | `待定 (Pending)` |
| **5. Savings Plans 覆盖** | [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | Compute Savings Plans 应用于生产 EKS 基线 | 生产基线 EC2 覆盖率 **≥ 80%** | `EVD-CST-005` | FinOps Lead | `待定 (Pending)` |
| **6. 日志归档生命周期** | [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-012`](../03-decisions/ADR-012-observability.md) | Fluent Bit 日志的 S3 Bucket 生命周期规则 | 日志在 30 天后自动从 S3 Standard 转为 Glacier | `EVD-OPS-002` | 运维 Lead | `待定 (Pending)` |
| **7. AWS 预算告警触发**| [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | AWS Budgets & Anomaly Detector 告警集成 | 在 85% 预算门槛时触发自动化的 Slack/邮件告警 | `EVD-CST-006` | FinOps Lead | `待定 (Pending)` |

---

## 3. 成本验证审计协议 (Cost Validation Audit Protocol)

### 测试 CST-01 — AWS 资源标签合规性审计
* **步骤**: 跨所有 AWS 账号 (`DataBlue-Test`, `DataBlue-Prod`, `Shared-Services`, `Security`) 运行 AWS Config 规则 `required-tags`。
* **必需标签 Key**: `Environment`, `BusinessSystem`, `CostCenter`, `Owner`。
* **通过标准**: 不合规未打标签的 AWS 资源数为 `0` (`EVD-CST-001`)。

### 测试 CST-02 — 月度消费模型偏差审计
* **步骤**: 提取 AWS Cost Explorer 月度账单，并与场景 2 生产基线进行对比。
* **通过标准**: AWS 总消费保持在 ±15% 门槛范围内；凭证附为 `EVD-CST-002`。
