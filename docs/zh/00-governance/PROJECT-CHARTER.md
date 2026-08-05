# 项目章程与治理规范 (Project Charter: DataBlue Next-Gen Infrastructure Platform)

---

## 1. 业务目标 (Business Objective)

**DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 项目的主要目标是在 AWS 云平台上设计、建模并建立企业级、高可用、动态可扩展且安全的云原生基础设施基线。

该平台将为一个统一且自动化的容器托管环境提供支撑，承载覆盖 5–6 个核心业务系统域的约 40 个微服务，并由企业级中间件（MySQL、RabbitMQ、MongoDB、Redis、Nacos）和统一的 CI/CD 工具链（GitLab、Jenkins、Ansible）提供全面支持。

核心业务目标包括：
* **业务敏捷性 (Business Agility)**: 通过自动化的应用部署 Pipeline，加速各业务系统的功能交付与迭代。
* **运维韧性 (Operational Resilience)**: 凭藉高可用性 (HA) 与灾难恢复 (DR) 能力，保障生产环境零单点故障 (Zero SPOF)。
* **成本可预测性 (Cost Predictability)**: 建立透明的 FinOps 成本估算与治理模型，防止 AWS 云成本超支。
* **治理与安全 (Governance & Security)**: 实施严格的环境隔离（测试环境 vs. 生产环境）与细粒度的访问权限管理。

---

## 2. 明确的包含范围 (Known Scope)

* **应用容量估算基线**: 结构化梳理跨 5-6 个业务系统约 40 个微服务的功能与容量需求。
* **多环境隔离架构**: 在 AWS 账号层级与 Kubernetes 集群边界层级实现测试环境与生产环境的完全物理/逻辑隔离。
* **自动化 CI/CD 集成**: 明确 GitLab、Jenkins 与 Ansible 之间的部署编排与工作流边界。
* **有状态中间件架构**: 对 MySQL、RabbitMQ、MongoDB、Redis 与 Nacos 的架构评估（AWS 托管服务 vs. EKS Operator 托管）。
* **多层级动态弹性伸缩**: 设计 Pod 动态扩缩容 (HPA)、节点扩缩容 (Karpenter/Cluster Autoscaler) 以及数据库扩展机制。
* **全栈可观测性与安全**: 涵盖 AWS 原生与开源的监控、日志、追踪、IAM RBAC 权限控制及密钥管理。
* **参数化成本估算**: 建立跨计算、存储、数据传输与中间件层级的 FinOps 成本基线模型。

---

## 3. 排除在外的范围 (Out of Scope)

* **应用代码重构**: 修改业务应用源码或编写应用层业务逻辑。
* **即刻基础设施资源创建**: 在阶段 0 / 阶段 1 期间部署真实 AWS VPC、EKS 集群或数据库实例。
* **CI/CD 脚本实时执行**: 在架构设计阶段执行真实的 Jenkins/Ansible 部署流水线。
* **自建旧架构物理迁移**: 物理服务器迁移或数据库存量数据的实际迁移执行。

---

## 4. 利益相关者矩阵 (Stakeholder Matrix)

| 利益相关者角色 | 主要职责 | 核心关注点与焦点 |
| :--- | :--- | :--- |
| **企业架构负责人 (Enterprise Architecture Lead)** | 总体技术治理、ADR 批准、平台标准强制执行 | 系统一致性、技术债务消除、安全合规 |
| **云工程 / DevOps 负责人 (Cloud & DevOps Lead)** | 基础设施设计、IaC 架构、CI/CD 流水线集成 | 运维可维护性、部署自动化、平台稳定性 |
| **业务系统产品负责人 (Product Owners)** | 定义业务系统 SLA、流量预期、部署频率 | 系统在线率、部署速度、发布干扰最小化 |
| **信息安全团队 (SecOps)** | IAM 权限控制、网络隔离、合规性监督 | 最小权限访问、数据加密、审计日志、爆炸半径控制 |
| **财务 / FinOps 团队 (Finance & FinOps Team)** | 成本模型审查、预算上限批准、云消费追踪 | AWS 成本详细估算、成本优化、资源合理化配置 |

---

## 5. 交付原则 (Delivery Principles)

1. **架构优先治理 (Architecture-First Governance)**: 在编写任何 IaC 代码之前，规范说明书、登记册和 ADR 必须完成并获得书面批准。
2. **可逆决策优先 (Reversible Decisions First)**: 在客户工作负载指标尚未完全确定前，优先选择灵活、模块化的架构抽象层。
3. **严格的环境隔离 (Strict Environment Segregation)**: 除非经过正式异常流程特许，测试环境与生产环境绝不允许共享单个 Kubernetes 集群。
4. **解耦的韧性定义 (Decoupled Resiliency Definitions)**: 在设计与目标 SLA 中，保持高可用 (HA)、备份 (Backup) 与灾难恢复 (DR) 的清晰解耦。
5. **基于凭证的就绪评估 (Evidence-Based Readiness)**: 未经实测基准测试与书面验收验证，任何系统或子系统不得声明为 Ready。

---

## 6. 关键成功指标 (Key Success Indicators - KPIs)

* **可追溯性索引**: 100% 的架构决策与 IaC 模块均可追溯回已登记的需求 (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`)。
* **ADR 完整性**: 针对所有核心权衡（EKS 拓扑、托管 vs 自建中间件、CI/CD 边界）提供正式的 ADR 决策记录覆盖。
* **环境爆炸半径**: 测试环境与生产环境之间保持 0 共享基础设施依赖。
* **成本预测偏差**: 输入工作负载指标后，AWS 实际消费与参数化成本模型基线的偏差控制在 ±15% 以内。
* **可用性合规**: 生产平台架构经过验证支持 Multi-AZ 高可用（目标 SLA ≥99.9%）。
