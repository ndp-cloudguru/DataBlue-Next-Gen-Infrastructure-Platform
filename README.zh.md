🌐 **语言 / Language / Ngôn ngữ**: [English](README.md) | [Tiếng Việt](README.vi.md) | [中文 (Chinese)](README.zh.md)

---

# DataBlue 下一代基础设施平台架构 (DataBlue Next-Gen Infrastructure Platform Architecture)

> **重要项目声明**: 基础设施具体代码实现（Terraform 模块、Kubernetes Manifest、Helm Chart、部署脚本或 AWS 真实资源创建）**尚未开始**。本仓库当前包含基于架构优先（Architecture-First Development）开发方法的阶段 0 需求基线、阶段 2 架构规范、阶段 3 决策与风险验证、阶段 4 实施计划、阶段 5 验证计划产物以及独立 Mermaid 架构图。

---

## 1. 项目概述 (Project Overview)

**DataBlue 下一代基础设施平台项目** (`datablue-nextgen-infra-platform`) 是一项企业级战略举措，旨在 Amazon Web Services (AWS) 上重构、规范、验证、建模成本、规划并建立生产级、高可用、安全且可动态扩展的云原生容器平台验证框架。

目标平台将承载：
* **业务系统**: 约 5–6 个业务系统域。
* **微服务**: 约 40 个分布式微服务，分别部署于独立的测试环境与生产环境。
* **数据库与中间件**: 关系型数据库 (MySQL)、分布式消息队列 (RabbitMQ)、文档数据库 (MongoDB)、内存缓存 (Redis) 以及服务注册与配置中心 (Nacos)。
* **CI/CD 与运维工具链**: GitLab 用于源码托管与 Pipeline 触发，Jenkins 用于构建/测试编排，Ansible 用于配置漂移管理与部署自动化。
* **平台能力**: 动态多层弹性伸缩、高可用、灾难恢复 (DR)、身份与访问权限管理 (IAM/RBAC)、全栈可观测性/监控、持续 FinOps 成本控制以及阶段 5 验证计划。

---

## 2. 当前项目状态 (Current Status)

* **阶段**: 阶段 5 — 验证计划与三语文档树基线 (Verification Planning & Trilingual Baseline)
* **状态**: **活跃 / 规划已完成 (ACTIVE / PLANNING COMPLETED)**
* **已完成里程碑**:
  * 项目宪章与治理规则 (`PROJECT-CHARTER.md`, `AGENTS.md`, `AGENTS.vi.md`)
  * 需求重构与规范化 (`REQUIREMENTS-REGISTER.md`)
  * 工程假设与开放问题登记册 (`ASSUMPTIONS-REGISTER.md`, `OPEN-QUESTIONS.md`)
  * 非功能性需求与验收标准定义 (`NON-FUNCTIONAL-REQUIREMENTS.md`, `ACCEPTANCE-CRITERIA.md`)
  * 阶段 2 完整架构规范 (`ARCHITECTURE-SPECIFICATION.md`)
  * 阶段 3 Master ADR 索引及 15 份独立 ADR 文档 (`ADR-001` 至 `ADR-015`)
  * 风险登记册、决策依赖图与架构验证包 (`RISK-REGISTER.md`, `DECISION-DEPENDENCIES.md`, `ARCHITECTURE-VALIDATION.md`)
  * 阶段 4 包含 11 个阶段的实施路线图 (`IMPLEMENTATION-ROADMAP.md`)
  * 包含 20 个工作包的工作分解结构 WBS (`WORK-BREAKDOWN-STRUCTURE.md`)
  * 验收门禁框架 `GATE-01` 至 `GATE-10` (`ACCEPTANCE-GATES.md`)
  * 参数化成本模型与场景 1 至 5 (`COST-MODEL.md`, `COST-SCENARIOS.md`)
  * 运维模型与支持就绪计划 (`OPERATING-MODEL.md`, `SUPPORT-READINESS-PLAN.md`)
  * 阶段 5 验证计划包（包含 `docs/zh/07-verification/`、`docs/en/07-verification/` 与 `docs/vi/07-verification/` 下的 11 个产物）
  * **三语文档树结构**（`docs/en/`、`docs/vi/` 与 `docs/zh/`，每棵树各包含 58 份 Markdown 文档）
  * **高管级提案发布包** (`final_proposal/` 包含 `PROPOSAL.vi.md`、`PROPOSAL.en.md` 与 `PROPOSAL.zh.md`)
  * 独立架构图目录 (`diagrams/src/`)
  * 多语言 AWS 成本分析 Excel 报告与 Generator (`cost_summary/`)

---

## 3. 仓库结构 (Repository Structure)

```text
datablue-nextgen-infra-platform/
├── README.md                                    # Master README 英文版
├── README.vi.md                                 # Master README 越南语版
├── README.zh.md                                 # Master README 中文版 (本文件)
├── AGENTS.md                                    # AI Agent 治理与门禁规则 (英文版)
├── AGENTS.vi.md                                 # AI Agent 治理与门禁规则 (越南语版)
├── final_proposal/                              # 高管级提案发布包 (多语言版本)
│   ├── README.md                                # 提案包索引与指南
│   ├── PROPOSAL.vi.md                           # 越南语 Master 提案 (官方主版本)
│   ├── PROPOSAL.en.md                           # 英文 Master 提案
│   └── PROPOSAL.zh.md                           # 中文 Master 提案 (中文版)
├── cost_summary/                                # 多语言 AWS 成本分析 Excel 报告与 Generator
│   ├── generate_cost_excel.py                   # Master Python OpenPyXL 成本生成脚本
│   ├── DataBlue_AWS_Cost_Analysis.xlsx          # 越南语详细成本分析 Excel
│   ├── DataBlue_AWS_Cost_Analysis_EN.xlsx       # 英文详细成本分析 Excel
│   └── DataBlue_AWS_Cost_Analysis_CN.xlsx       # 中文详细成本分析 Excel
├── diagrams/                                    # 独立 Mermaid 架构图目录
│   ├── README.md                                # 架构图索引与渲染指南
│   ├── render.py                                # Python 自动渲染编译脚本
│   └── src/                                     # 原始 .mmd 源码文件
├── scenarios/                                   # 5 个场景的 Terraform 基础设施即代码 (IaC) 目录
│   ├── README.md                                # 场景指南与 Terraform 执行流程
│   ├── modules/                                 # 8 个生产级可复用 Terraform 核心模块
│   │   ├── vpc/                                 # 3 层 VPC 网络 topology (Public, Private App, Isolated DB)
│   │   ├── kms/                                 # AWS KMS 客户托管密钥 (CMK)
│   │   ├── eks/                                 # Amazon EKS v1.30+ 控制平面、IRSA 与 Karpenter Roles
│   │   ├── rds_mysql/                           # Amazon RDS MySQL Multi-AZ 具备 30 天 PITR 备份
│   │   ├── elasticache_redis/                   # Amazon ElastiCache Redis 集群具备 TLS 与 Auth Token
│   │   ├── amazon_mq_rabbitmq/                  # Amazon MQ RabbitMQ 3 节点 Quorum Broker
│   │   ├── documentdb/                          # Amazon DocumentDB 3 节点集群 (MongoDB 兼容)
│   │   └── opensearch/                          # Amazon OpenSearch Service Multi-AZ 集群
│   ├── scenario-1-test-baseline/                # 场景 1: 标准非生产测试环境 ($1,600-$2,400/月)
│   ├── scenario-2-prod-baseline/                # 场景 2: 生产基线环境 ($4,200-$6,100/月)
│   ├── scenario-3-prod-high-scale-ha/           # 场景 3: 生产大规模高可用环境 ($7,200-$10,500/月)
│   ├── scenario-4-prod-cross-region-dr/         # 场景 4: 生产跨区域灾难恢复 DR ($10,000-$14,800/月)
│   └── scenario-5-enterprise-multi-account/     # 场景 5: 企业级多账号隔离架构 ($12,000-$18,500/月)
└── docs/
    ├── en/                                      # 英文文档树 (58 份 Markdown 文档)
    ├── vi/                                      # 越南语文档树 (58 份 Markdown 文档)
    └── zh/                                      # 中文文档树 (58 份 Markdown 文档 - 中文文档树)
        ├── 00-governance/
        ├── 01-requirements/
        ├── 02-architecture/
        ├── 03-decisions/
        ├── 04-planning/
        ├── 05-cost/
        ├── 06-operations/
        ├── 07-verification/
        ├── 08-risks/
        └── PROPOSAL.md
```

---

## 4. 需求标识符与命名规范 (Requirement Identifiers)

所有项目产物均严格遵守标准化 ID 格式，以确保在规范、ADR、工作包和验证测试用例之间保持 100% 的交叉可追溯性：

* **业务需求**: `BUS-001` 至 `BUS-004` (高管业务目标与成本目标)
* **功能需求**: `FUN-001` 至 `FUN-009` (微服务、CI/CD、数据库与 Nacos 平台能力)
* **非功能需求**: `NFR-001` 至 `NFR-003` (99.9% 高可用、分钟级弹性伸缩与 DR RTO/RPO SLAs)
* **安全需求**: `SEC-001` 至 `SEC-003` (IRSA OIDC 身份认证、隔离子网、KMS 加密与 Cloudflare WAF)
* **运维与可观测性**: `OPS-001` 至 `OPS-003` (OpenSearch 集中日志、Prometheus/Grafana APM 与 FinOps 控制)
* **成本管理需求**: `CST-001` 至 `CST-002` (参数化成本场景 1–5 与 Savings Plans 策略)
* **工程假设**: `ASM-001` 至 `ASM-005` (工作负载指标与容量假设)
* **架构决策记录**: `ADR-001` 至 `ADR-015` (主技术选型包)
* **工作包与门禁**: `WP-001` 至 `WP-020`, `GATE-01` 至 `GATE-10` (11 阶段实施路线图)

---

## 5. 导航与快速访问 (Navigation)

* **高管级提案发布包**: [`final_proposal/`](final_proposal/)
* **执行提案 (越南语 - 主版本)**: [`final_proposal/PROPOSAL.vi.md`](final_proposal/PROPOSAL.vi.md)
* **执行提案 (英文)**: [`final_proposal/PROPOSAL.en.md`](final_proposal/PROPOSAL.en.md)
* **执行提案 (中文)**: [`final_proposal/PROPOSAL.zh.md`](final_proposal/PROPOSAL.zh.md)
* **中文文档索引树**: [`docs/zh/`](docs/zh/)
* **英文文档索引树**: [`docs/en/`](docs/en/)
* **越南语文档索引树**: [`docs/vi/`](docs/vi/)
* **独立 Mermaid 架构图**: [`diagrams/`](diagrams/)
* **多语言 Excel 成本分析与 Generator**: [`cost_summary/`](cost_summary/)
* **AI Agent 治理规则 (英文版)**: [`AGENTS.md`](AGENTS.md)
* **AI Agent 治理规则 (越南语版)**: [`AGENTS.vi.md`](AGENTS.vi.md)
