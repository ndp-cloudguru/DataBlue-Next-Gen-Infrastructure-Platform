# 验收门槛治理框架 (Acceptance Gates Framework: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档制定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的正式 **验收门槛治理框架 (Acceptance Gates Framework)**。

每个项目阶段的过渡均由强制性的验收门槛控制。**未经指定的审批人进行正式的人工签署，任何阶段均不得擅自推进。**

---

## 2. 主验收门槛目录 (Master Acceptance Gates Catalog: `GATE-01` 至 `GATE-10`)

### `GATE-01`: 需求基线批准 (Requirement Baseline Approval)
* **阶段过渡**: 阶段 0 完成 $\rightarrow$ 阶段 1 开始
* **所需凭证**: 规范化的 [`REQUIREMENTS-REGISTER.md`](../01-requirements/REQUIREMENTS-REGISTER.md), [`PROJECT-CHARTER.md`](../00-governance/PROJECT-CHARTER.md) 及 [`AGENTS.md`](../../AGENTS.md)。
* **授权审批人**: 项目发起人 (Project Sponsor), 企业架构 Lead (Enterprise Architecture Lead)
* **通过条件**: 100% 的需求分配了标准化的 ID (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`)。
* **失败处理**: 暂停项目执行；退回阶段 0 重新进行需求规范化。
* **返工路径**: 更新 `REQUIREMENTS-REGISTER.md` 并重新提交。

---

### `GATE-02`: 架构规范说明书批准 (Architecture Specification Approval)
* **阶段过渡**: 阶段 2 架构完成 $\rightarrow$ 阶段 3 ADR 验证开始
* **所需凭证**: 包含 17 个章节的 [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md)。
* **授权审批人**: 云架构主工程师 (Lead Cloud Architect), 企业架构委员会 (Enterprise Architecture Board)
* **通过条件**: 完全覆盖系统 Context、逻辑架构、部署架构、网络架构、安全架构、高可用性 (HA)、可扩展性、可观测性、备份、灾难恢复 (DR)、成本及 Stack 选型。
* **失败处理**: 拒绝架构基线；要求对文档进行修订。
* **返工路径**: 更新 `ARCHITECTURE-SPECIFICATION.md` 并重新提交。

---

### `GATE-03`: ADR 决策包批准 (ADR Package Approval)
* **阶段过渡**: 阶段 3 决策完成 $\rightarrow$ 阶段 1 AWS 基础设施执行开始
* **所需凭证**: Master [`ADR-REGISTER.md`](../03-decisions/ADR-REGISTER.md) 及 15 个独立的 ADR 文档 (`ADR-001`..`015`)。
* **授权审批人**: 企业架构委员会, 云安全 Lead, FinOps Lead
* **通过条件**: 提议的 ADRs (`ADR-001`..`005`, `ADR-010`..`013`, `ADR-015`) 获得正式的人工接收签署。
* **失败处理**: 阻断 IaC 代码执行 (`AGENTS.md`)。
* **返工路径**: 修订 ADR 权衡备选方案，并重新提交给架构委员会。

---

### `GATE-04`: AWS 基础就绪 (AWS Foundation Ready)
* **阶段过渡**: 阶段 1 基础完成 $\rightarrow$ 阶段 2 测试平台开始
* **所需凭证**: 已拉起的 AWS Landing Zone、S3 状态 Bucket、VPC 子网、NAT 网关及 KMS 密钥 (`WP-002`..`WP-004`)。
* **授权审批人**: 基础设施主架构师 (Infrastructure Lead Architect), 云安全 Lead (Cloud Security Lead)
* **通过条件**: 100% 加密存储；数据库子网与公网之间零路由路径 (`SEC-002`)。
* **失败处理**: 销毁不合规的 VPC 子网。
* **返工路径**: 修复 Terraform 网络模块并重新 Apply 部署。

---

### `GATE-05`: 测试平台就绪 (Test Platform Ready)
* **阶段过渡**: 阶段 2 测试平台完成 $\rightarrow$ 阶段 3 共享服务开始
* **所需凭证**: 可运行的测试 EKS 集群 (`v1.30+`)、功能性 ALB Ingress Controller、Cloudflare DNS / GTM 以及 IRSA IAM 集成 (`WP-005`, `WP-006`)。
* **授权审批人**: DevOps Lead, 基础设施架构师 (Infrastructure Architect)
* **通过条件**: `kubectl get nodes` 在 3 个可用区中均返回 `Ready`；测试 Ingress 端点获得 SSL Labs A 级评级。
* **失败处理**: 暂停共享服务安装。
* **返工路径**: 重新拉起 EKS 节点组与 Ingress Controllers。

---

### `GATE-06`: 技术试点验收通过 (Technical Pilot Accepted)
* **阶段过渡**: 阶段 6 技术试点完成 $\rightarrow$ 阶段 7 生产建设开始
* **所需凭证**: 技术试点验收基准报告 (`WP-014`)。
* **授权审批人**: 应用架构主工程师, SRE Lead, DevOps Lead
* **通过条件**: Karpenter 节点拉起延迟 < 60 秒；在 100% 突发负载下 0 次 HTTP 500 错误；验证通过 Grafana Dashboard。
* **失败处理**: 阻断生产环境建设；优化试点微服务配置。
* **返工路径**: 调优 Karpenter NodePool CRDs 并重新运行压力测试。

---

### `GATE-07`: 生产建设批准 (CAB 签署: Production Build Approval)
* **阶段过渡**: 阶段 6 完成 $\rightarrow$ 阶段 7 生产基础设施创建开始
* **所需凭证**: 签署的变更咨询委员会 (CAB) 授权 Ticket、试点基准测试结果、成本模型签署。
* **授权审批人**: 变更咨询委员会 (CAB), 企业安全 Lead, FinOps Lead
* **通过条件**: 获得创建 `DataBlue-Prod-Account` 的正式书面授权。
* **失败处理**: 严格禁止创建生产云资源 (`AGENTS.md`)。
* **返工路径**: 解决 CAB 关于安全或预算的异议并重新提交 Ticket。

---

### `GATE-08`: 生产就绪验收通过 (Production Readiness Accepted)
* **阶段过渡**: 阶段 9 就绪完成 $\rightarrow$ 阶段 10 运维交接开始
* **所需凭证**: 生产就绪与灾难恢复验证报告 (`WP-018`)。
* **授权审批人**: 云架构主工程师, 企业安全 Lead, 业务产品负责人
* **通过条件**: 验证通过 30 天数据库 PITR 恢复；成功的模拟可用区故障转移；满足 RTO/RPO SLA 的跨区域 DR 故障转移测试。
* **失败处理**: 阻断生产 Go-Live 上线。
* **返工路径**: 修复故障转移瓶颈并重新运行 DR 演练。

---

### `GATE-09`: 迁移波次签署 (Migration Wave Sign-Off)
* **阶段过渡**: 按迁移波次 (Waves 1 至 5) $\rightarrow$ 下一迁移波次
* **所需凭证**: 波次准出标准验证报告 (`MIGRATION-ONBOARDING-PLAN.md`)。
* **授权审批人**: 业务系统产品负责人, DevOps Lead
* **通过条件**: 波次中 100% 的微服务处于 `Ready` 状态；HTTP 5xx 错误率 < 0.01%；完成 14 天 Hypercare 重点保障期。
* **失败处理**: 执行波次回滚 Playbooks (`ROLLBACK-STRATEGY.md`)。
* **返工路径**: 重新部署前在测试环境中修复微服务容器 Bug。

---

### `GATE-10`: 运维交接验收通过 (Operational Handover Acceptance)
* **阶段过渡**: 阶段 10 完成 $\rightarrow$ 持续平台运维
* **所需凭证**: 签署的运维交接证书、验证通过的 Runbooks、权限交接审计。
* **授权审批人**: 企业运维 / SRE Lead, 项目发起人
* **通过条件**: 运维团队培训完毕；100% 的告警路由至 PagerDuty/Slack；Runbooks 完成验证。
* **失败处理**: 延长项目团队的 Hypercare 保障期。
* **返工路径**: 开展额外的 SRE 培训课程并更新运维 Runbooks。
