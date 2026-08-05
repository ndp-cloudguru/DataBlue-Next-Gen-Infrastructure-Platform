# 工作分解结构说明书 (Work Breakdown Structure: DataBlue Platform)

---

## 1. 治理与结构 (Governance & Structure)

本文档制定了交付 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的完整 **工作分解结构 (WBS)**。

每个工作包 (Work Package) 均可追溯至需求 ID (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`)、架构决策记录 (`ADR`) 及风险 ID (`RSK`)。

---

## 2. 工作包目录 Catalog (`WP-001` 至 `WP-020`)

### `WP-001`: 工作负载凭证收集与剖析框架
* **描述**: 在非生产环境中建立剖析工具，收集约 40 个微服务的 CPU、RAM、IOPS 和 RPS 指标 (`OPEN-001`)。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **关联风险**: `RSK-UNC-001`, `RSK-UNC-002`, `RSK-DAT-001`
* **依赖项**: 无 (阶段 0)
* **交付物**: 验证通过的工作负载剖析报告及解决的中间件 ADRs。
* **准出标准**: 100% 的微服务容量容量指标被记录并获得签署批准。

---

### `WP-002`: AWS Landing Zone 与多账号结构搭建
* **描述**: 搭建多账号 AWS Organization 结构 (`DataBlue-Test`, `DataBlue-Prod`, `Shared-Services`, `Security-Account`)。
* **关联需求**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-015`](../03-decisions/ADR-015-infrastructure-as-code.md)
* **依赖项**: `WP-001`, [`GATE-03`](ACCEPTANCE-GATES.md)
* **交付物**: 包含远程 S3 Terraform State Backend 的预置 AWS 账号。
* **准出标准**: [`GATE-04`](ACCEPTANCE-GATES.md) 签署通过。

---

### `WP-003`: IAM Identity Center、IRSA Role 与安全基线配置
* **描述**: 配置集中式 IAM Identity Center、EKS 的 OIDC 提供商以及 IAM Roles for Service Accounts (IRSA)。
* **关联需求**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **依赖项**: `WP-002`
* **准出标准**: 零通配符 (`*`) IAM 权限检测输出。

---

### `WP-004`: VPC 网络架构、子网与路由配置
* **描述**: 跨 3 个可用区部署 3 层 VPC 网络拓扑（Public, Private Application, Isolated Database 子网）。
* **关联需求**: [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md)
* **依赖项**: `WP-002`
* **准出标准**: 隔离数据库子网与公网之间零路由路径。

---

### `WP-005`: 测试 EKS 控制平面与工作节点组建设
* **描述**: 在 `DataBlue-Test-Account` 中跨 3 可用区部署专有的测试 EKS 集群 (`v1.30+`)。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md), [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md)
* **依赖项**: `WP-003`, `WP-004`
* **准出标准**: [`GATE-05`](ACCEPTANCE-GATES.md) 签署通过。

---

### `WP-006`: 测试环境 Ingress、DNS 与 TLS 证书集成
* **描述**: 安装 AWS Load Balancer Controller，配置 Cloudflare DNS 与 AWS Private Hosted Zones，签发 ACM TLS 证书。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **依赖项**: `WP-005`

---

### `WP-007`: Shared GitOps Controller (ArgoCD) 部署
* **描述**: 在 EKS 中部署 ArgoCD 引擎，控制核心平台组件的声明式发布。
* **关联需求**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md), [`ADR-015`](../03-decisions/ADR-015-infrastructure-as-code.md)
* **依赖项**: `WP-005`

---

### `WP-008`: Karpenter JIT 自动扩缩容引擎配置
* **描述**: 部署 Karpenter Controller 和 NodePool CRDs，实现节点级即时扩缩容。
* **关联需求**: [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md)
* **依赖项**: `WP-005`

---

### `WP-009`: External Secrets Operator (ESO) 集成
* **描述**: 部署 ESO 并与 AWS Secrets Manager 绑定，实现安全的 Pod 密钥自动注入。
* **关联需求**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **依赖项**: `WP-003`, `WP-005`

---

### `WP-010`: 全栈可观测性 Stack 部署 (Prometheus, Grafana, OpenSearch)
* **描述**: 部署 Prometheus Operator、Grafana Dashboard 及 Fluent Bit 转发器至 Amazon OpenSearch。
* **关联需求**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **依赖项**: `WP-005`

---

### `WP-011`: CI/CD 流水线自动化 (GitLab + Jenkins + Ansible)
* **描述**: 建立由 GitLab 触发、Jenkins 执行构建并推送到 ECR、Ansible 执行部署的自动化流水线。
* **关联需求**: [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **依赖项**: `WP-007`

---

### `WP-012`: 有状态中间件集群部署与配置
* **描述**: 部署并验证 MySQL、Redis、RabbitMQ、MongoDB 及 Nacos 集群。
* **关联需求**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md)
* **依赖项**: `WP-005`, `WP-009`

---

### `WP-013`: 备份与可恢复性机制部署 (Velero + PITR)
* **描述**: 部署 Velero 备份 EKS 集群状态，配置数据库 30 天 PITR 备份与 S3 跨账号复制。
* **关联需求**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **依赖项**: `WP-012`

---

### `WP-014`: 技术试点应用上线与基准测试
* **描述**: 部署代表性的 5 服务试点套件，执行压力测试并校验 Karpenter 与 Grafana。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **依赖项**: `WP-011`, `WP-012`
* **准出标准**: [`GATE-06`](ACCEPTANCE-GATES.md) 签署通过。

---

### `WP-015`: 生产环境 AWS 基础设施建设
* **描述**: 在 `DataBlue-Prod-Account` 中拉起生产 AWS VPC、安全组、EKS 集群与数据库。
* **关联需求**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md)–[`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md)
* **依赖项**: `WP-014`, [`GATE-07`](ACCEPTANCE-GATES.md)
* **准出标准**: [`GATE-07`](ACCEPTANCE-GATES.md) 签署通过。

---

### `WP-016`: 生产环境应用分波次迁移 (Waves 1 至 5)
* **描述**: 跨 5 个波次，系统化地将约 40 个微服务迁移至生产环境。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **依赖项**: `WP-015`
* **准出标准**: [`GATE-09`](ACCEPTANCE-GATES.md) 签署通过。

---

### `WP-017`: 生产可观测性、告警与 FinOps 归因
* **描述**: 配置生产环境 Grafana 告警规则、PagerDuty 集成及 AWS Cost Categories。
* **关联需求**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **依赖项**: `WP-016`

---

### `WP-018`: 生产就绪与 DR 混沌演练
* **描述**: 执行节点崩溃、AZ 停机、数据库主节点切换及跨区域 DR 故障转移演练。
* **关联需求**: [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **依赖项**: `WP-016`
* **准出标准**: [`GATE-08`](ACCEPTANCE-GATES.md) 签署通过。

---

### `WP-019`: 运维 Runbooks 与 SRE 团队培训
* **描述**: 编写全套运维 Runbooks 并对企业 SRE 团队开展运维交接培训。
* **关联需求**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **依赖项**: `WP-018`

---

### `WP-020`: 最终平台交接与支持验收
* **描述**: 移交云账号最高管理权限并完成平台运维的正式交接。
* **关联需求**: [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **依赖项**: `WP-019`
* **准出标准**: [`GATE-10`](ACCEPTANCE-GATES.md) 签署通过。
