# ADR-004 — CI/CD 运维与工具链模式 (CI/CD Operating Model)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: DevOps 主工程师 (DevOps Lead), 基础设施架构师 (Infrastructure Architect)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), 安全团队 (Security Team)
* **关联需求**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-SEC-001` (CI/CD 流水线凭据泄露风险), `RSK-ARC-001` (多工具流水线职责漂移)
* **关联假设**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 6 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
客户需求规定需要同时集成 GitLab (`FUN-002`)、Jenkins (`FUN-003`) 和 Ansible (`FUN-004`) 以实现自动化部署 (`BUS-002`)。我们必须定义一个运维模型，以防止流水线步骤重复、配置漂移以及安全凭据暴露。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **工具链合规性**: 满足客户关于 GitLab、Jenkins 和 Ansible 的具体指示。
2. **清晰的运维职责切割**: 绘制明确的边界，使每个工具仅处理单一的职责域。
3. **流水线凭据安全**: 将部署凭据限定在安全的专有执行 Agent 内部 (`SEC-001`)。
4. **GitOps 与配置漂移控制**: 确保目标环境状态保持声明式与可审计性 (`BUS-002`)。

---

## 3. 约束条件 (Constraints)
* 必须按照功能需求强规集成 GitLab、Jenkins 和 Ansible。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: 纯 GitLab CI/CD (绕过 Jenkins 与 Ansible)
* **描述**: 仅使用 GitLab CI/CD 进行源码控制、容器构建、测试和部署。
* **优势**: 高度简化的单厂商 CI/CD 流水线；简单的开发者工作流。
* **劣势**: 违反需求 `FUN-003` (Jenkins) 和 `FUN-004` (Ansible)；忽略了客户现有的 Jenkins/Ansible 工具投资。
* **安全性影响**: 良好的集中式密钥管理。
* **相关风险**: 违反客户平台硬性标准。

### 方案 2: 纯 Jenkins CI/CD (绕过 GitLab CI 与 Ansible)
* **描述**: 直接通过 Jenkins 中的 Webhook 触发构建，执行容器构建，并通过 Jenkins 插件直接运行部署脚本。
* **优势**: 充分利用现有的 Jenkins 构建脚本资产。
* **劣势**: 命令式脚本泛滥的高风险；绕过 Ansible 配置漂移控制 (`FUN-004`)；Jenkins Slave 内部复杂的凭据管理。
* **安全性影响**: 弱。直接在 Jenkins 构建节点上存储云部署密钥。
* **相关风险**: 流水线配置漂移与凭据暴露 (`RSK-SEC-001`)。

### 方案 3: 混合覆盖运维模型 (GitLab → Jenkins → Ansible + GitOps) — 推荐方案
* **描述**: 建立解耦的多工具流水线架构：
  1. **GitLab**: 源码版本控制、Merge Request 触发与 Webhook 派发 (`FUN-002`)。
  2. **Jenkins**: CI 构建、单元测试、容器漏洞扫描、镜像打包与 ECR 推送 (`FUN-003`)。
  3. **Ansible**: 基础设施配置管理、环境漂移修复与部署指令执行 (`FUN-004`)。
  4. **ArgoCD / GitOps**: Kubernetes Manifest 的集群内部声明式状态同步 (`BUS-002`)。
* **优势**: 100% 满足客户工具链需求；建立清晰的域隔离；通过将 IAM 权限严格限定在 Ansible 控制节点 / ArgoCD 服务账号内部，消除了凭据暴露隐患。
* **劣势**: 多工具运维叠加需要严格的流水线接口规范文档 (`RSK-ARC-001`)。
* **安全性影响**: 强。跨流水线阶段实施严格的最小权限 IAM Role 隔离。
* **可用性影响**: 高。隔离的工具链故障域。
* **可扩展性影响**: 高。弹性 Spot Jenkins 构建 Agent。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: 纯 GitLab | 方案 2: 纯 Jenkins | 方案 3: 混合覆盖架构 (GitLab+Jenkins+Ansible) |
| :--- | :--- | :--- | :--- |
| **需求合规 (`FUN-002..004`)** | 弱 (违反需求) | 弱 (违反需求) | **强 (100% 合规)** |
| **凭据安全** | 中等 | 弱 | **强 (Strong)** |
| **漂移控制** | 中等 | 弱 | **强 (Strong)** |
| **运维清晰度** | 高 | 低 | **中-高 (Moderate-High)** |
| **可逆性** | 可逆 | 困难 | **易于扩展/可逆** |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 3: 混合覆盖运维模型** (GitLab 用于源码/触发 $\rightarrow$ Jenkins 用于 CI 构建/打包 $\rightarrow$ Ansible 用于配置/部署 + GitOps)。

---

## 7. 决策依据 (Rationale)
方案 3 严格满足了功能需求 `FUN-002`、`FUN-003` 和 `FUN-004`，同时建立了清晰的安全边界，防止 Jenkins Runner 存储长期云部署凭据 (`SEC-001`)。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 100% 满足客户工具链需求；安全的流水线凭据；通过 Ansible 实现自动化的漂移管理。
* **负面影响**: 需要维护多个工具集成点。
* **新增运维职责**: 维护 GitLab Webhook、Jenkins Job 和 Ansible 执行主机之间的 API 触发契约。
* **新增风险**: `RSK-ARC-001` (流水线接口契约漂移)。
* **成本影响**: Jenkins Master 和 Ansible 控制服务器的 EC2 节点开销。

---

## 9. 验证凭证 (Validation Evidence)
* 共享服务账号中的 Webhook 触发模拟与端到端流水线测试运行。

## 10. 验收条件 (Acceptance Conditions)
* DevOps 负责人与安全团队签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* 客户决定将 CI/CD 工具链统一收敛至单个 SaaS 平台。

## 12. 实施影响 (Implementation Implications)
* Ansible Playbooks 与 Jenkins Pipelines 将在阶段 3 编写。
