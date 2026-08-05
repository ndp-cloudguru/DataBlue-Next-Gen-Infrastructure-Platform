# ADR-001 — AWS 账号架构策略 (AWS Account Strategy)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 云架构主工程师 (Lead Cloud Architect), 企业安全负责人 (Enterprise Security Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), DevOps 负责人 (DevOps Lead)
* **关联需求**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-SEC-003` (跨环境爆炸半径), `RSK-CST-001` (不受控的成本分摊)
* **关联假设**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md) (AWS 账号层级隔离)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 4 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
DataBlue 平台必须在独立的测试和生产环境中承载跨 5-6 个业务系统的约 40 个微服务 (`BUS-001`, `BUS-003`)。组织要求实施严格的安全访问控制、隔离的爆炸半径以及明确的成本归因。我们需要决定如何构建 AWS 账号边界。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **安全与爆炸半径隔离**: 防止测试环境中的误配置或受安全攻击影响到生产环境 (`SEC-002`)。
2. **成本归因与账单隔离**: 按环境实现精准、无摩擦的成本核算与分摊 (`CST-002`)。
3. **AWS 服务限额自主性**: 避免测试与生产工作负载之间的 API 频率限制 (Rate Limiting) 或配额竞争。
4. **合规与审计一致性**: 集中式审计日志 (CloudTrail) 与最小权限管理访问。

---

## 3. 约束条件 (Constraints)
* 必须在 AWS 云生态系统内部原生运行。
* 必须支持通过 AWS Organizations 进行集中式治理。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: 单 AWS 账号 (测试与生产混合部署)
* **描述**: 所有工作负载托管在单个 AWS 账号中，通过 VPC 和 IAM 标签区分环境。
* **优势**: 初始搭建简单；账号管理开销最低。
* **劣势**: 严重的爆炸半径风险；共享 AWS API 限流；复杂的 IAM 策略；误删除生产资源的风险。
* **安全性影响**: 弱。跨环境误授权极为常见。
* **可用性影响**: 低。测试环境流量激增可能触发 AWS API 限流，直接影响生产环境。
* **可扩展性影响**: 中等。共享账号配额（如 Elastic IPs, VPC limits）。
* **运维影响**: 运维管理操作期间存在极高的运维风险。
* **成本影响**: 难以精准隔离共享资源成本。
* **厂商绑定**: 低。
* **迁移复杂度**: 如果后续被迫拆分账号，迁移复杂度极高。
* **可逆性**: 一旦资源部署完成，极难撤销重构。
* **前置条件**: 无。
* **相关风险**: `RSK-SEC-003` (严重的安全爆炸半径漏洞)。

### 方案 2: 双独立账号 (专有测试账号与生产账号)
* **描述**: 创建两个独立的 AWS 账号（一个测试账号，一个生产账号）。
* **优势**: 良好的环境隔离；测试与生产之间账单边界清晰。
* **劣势**: 缺少用于集中安全日志记录和共享 CI/CD 工具的专有账号。
* **安全性影响**: 中等至良好。良好的环境隔离，但安全日志仍然混合存储。
* **可用性影响**: 高。测试环境异常不会影响生产环境 API 限额。
* **可扩展性影响**: 高。每个环境拥有独立的 AWS 服务配额。
* **运维影响**: 中等的管理开销。
* **成本影响**: 运行时环境具备清晰的成本隔离。
* **厂商绑定**: 低。
* **迁移复杂度**: 中等。
* **可逆性**: 可通过迁移实施撤销。
* **前置条件**: AWS Organizations 配置。
* **相关风险**: 共享 CI/CD Runner 跨环境访问凭据的安全风险。

### 方案 3: 多账号 Landing Zone (AWS Organizations Control Tower) — 推荐方案
* **描述**: 划分 4 个专有 AWS 账号：安全/日志账号 (Security/Logging)、共享服务账号 (Shared Services: GitLab/Jenkins/ECR)、测试账号 (Test)、生产账号 (Production)。
* **优势**: 最大化安全隔离；集中式不可变审计日志；专有的共享 CI/CD 流水线边界；独立账单核算。
* **劣势**: 初始搭建复杂度稍高；需要跨账号 IAM Role 治理。
* **安全性影响**: 极佳。测试与生产之间零共享 IAM 凭据；集中式 S3 安全日志归档。
* **可用性影响**: 极佳。配额与运行时完全独立。
* **可扩展性影响**: 极佳。可扩展的组织单元 (OU) 模型。
* **运维影响**: 需要具备 AWS Control Tower / IAM Identity Center 管理能力。
* **成本影响**: 标称的 AWS 固定开销（如每个账号的 AWS Config, GuardDuty）。
* **厂商绑定**: 中等 (AWS Control Tower 架构)。
* **迁移复杂度**: 中等。
* **可逆性**: 易于撤销 / 扩展。
* **前置条件**: 启用 AWS Organizations。
* **相关风险**: 跨账号网络 Peering 对等连接复杂度。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: 单账号 | 方案 2: 双账号 | 方案 3: 多账号 Landing Zone |
| :--- | :--- | :--- | :--- |
| **安全与爆炸半径** | 弱 | 中等 | **强 (Strong)** |
| **可用性隔离** | 弱 | 强 | **强 (Strong)** |
| **成本归因** | 弱 | 中等 | **强 (Strong)** |
| **运维复杂度** | 低 | 中等 | 中等 |
| **可逆性** | 困难 | 可逆 | **易于扩展/可逆** |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 3: 多账号 Landing Zone 架构** (Security/Logging, Shared Services, Test, Production)。

---

## 7. 决策依据 (Rationale)
方案 3 提供了最强的纵深防御安全边界 (`SEC-002`)，强制实施不可变的审计日志 (`OPS-002`)，并在不影响可用性的前提下满足 FinOps 成本归因需求 (`CST-002`)。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 完全的爆炸半径隔离；零 API 限流竞争；清晰的环境账单分摊。
* **负面影响**: 跨账号 IAM Role 初始搭建开销较高。
* **新增运维职责**: AWS Control Tower 治理与跨账号 IAM Role 访问管理。
* **新增风险**: 跨账号 IAM Trust 信任关系配置错误的风险。
* **成本影响**: 多账号安全服务 (GuardDuty, Config) 产生的标称固定月度支出。

---

## 9. 验证凭证 (Validation Evidence)
* AWS Control Tower 基线配置审查及 IAM 跨账号 Role 审计。

## 10. 验收条件 (Acceptance Conditions)
* 企业安全负责人与云架构主工程师的书面签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* AWS Organization 架构重构或监管合规范围发生变更。

## 12. 实施影响 (Implementation Implications)
* 多账号结构将在阶段 3 通过模块化 IaC (Terraform) 进行自动拉起创建。
