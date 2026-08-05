# 平台风险登记册说明书 (Risk Register: DataBlue Platform)

---

## 1. 治理与风险分类法 (Governance & Risk Taxonomy)

本文档包含了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的完整 **风险登记册 (Risk Register)**。

风险划分为 10 个标准化的领域分类法：
1. **需求不确定性** (`RSK-UNC`): 缺少客户工作负载数据、未确认的容量规格、未声明的目标。
2. **架构风险** (`RSK-ARC`): 多工具集成复杂度、结构性权衡取舍。
3. **可用性风险** (`RSK-AVL`): 停机事故、Multi-AZ 与 DR 概念混淆、区域级故障暴露。
4. **可扩展性风险** (`RSK-SCL`): 容量瓶颈、Pod/节点扩容限制、数据库连接数限制。
5. **安全风险** (`RSK-SEC`): 访问控制、凭据暴露、爆炸半径、过度授权的 IAM 权限。
6. **数据风险** (`RSK-DAT`): 数据库协议不兼容、未验证的备份恢复。
7. **运维风险** (`RSK-OPS`): 运维维护负担、缺少 SLOs、生产变更控制。
8. **成本风险** (`RSK-CST`): 托管服务成本激增、不受控的自动扩缩容消费、可观测性日志膨胀。
9. **供应商依赖** (`RSK-VND`): 云厂商绑定 vs 开源运维维护。
10. **交付风险** (`RSK-DEL`): IaC 模块复杂度、进度延误。

---

## 2. 完整风险日志 (Comprehensive Risk Log)

### 1. 需求不确定性 (`RSK-UNC`)

#### `RSK-UNC-001`: 缺少 CPU 与内存工作负载 Profiles
* **风险陈述**: 跨约 40 个微服务缺乏单个服务的 CPU 和内存指标，可能导致严重的节点规格配置错误。
* **类别**: 需求不确定性
* **原因**: 客户无法在阶段 0 提供容器剖析指标 (`OPEN-001`)。
* **后果**: 过度预置 AWS 节点（高额浪费）或预置不足（应用 Pod 循环崩溃）。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)
* **概率**: 高 | **影响**: 高 | **暴露度**: 高
* **现有控制**: 初始临时代号规格分层 (`ASM-006`)。
* **提议缓解措施**: 部署 Karpenter JIT 自动扩缩容引擎 (`ADR-005`)，并在测试环境中运行容器剖析测试。
* **应急预案**: 部署动态 Pod 资源推荐器 (Goldilocks / VPA) 动态调整 Request 限额。
* **责任人**: FinOps 分析师 / 云架构师 | **状态**: 激活 (Active)

#### `RSK-UNC-002`: 缺少流量 RPS 与并发信息
* **风险陈述**: 缺少峰值每秒请求数 (RPS) 与并发用户连接指标，存在网络与负载均衡器限流的风险。
* **类别**: 需求不确定性
* **原因**: 客户未声明流量 Profiles。
* **后果**: Ingress ALB Target Group 耗尽及 API HTTP 504 超时。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **概率**: 高 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 在阶段 3 原型设计期间执行模拟压力测试。
* **责任人**: 基础设施主架构师 | **状态**: 激活 (Active)

#### `RSK-UNC-003`: 缺少数据容量与存储增长率
* **风险陈述**: 缺少数据库存储基线与月度增长率，存在 EBS 卷空间耗尽或预算超支的风险。
* **类别**: 需求不确定性
* **原因**: 客户数据库指标未确认。
* **后果**: 由于磁盘空间满导致数据库写入失败。
* **关联需求**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md), [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **概率**: 高 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 向客户 DBA 征集当前现有数据库的磁盘使用量。
* **责任人**: 数据库管理员 (DBA) | **状态**: 激活 (Active)

#### `RSK-UNC-004`: 约 40 个微服务的关键性与依赖关系未知
* **风险陈述**: 对所有 40 个微服务一视同仁，存在错误分配高可用与备份资源的风险。
* **类别**: 需求不确定性
* **原因**: 缺少业务系统分级定义 (Tier 1 核心关键 vs Tier 3 批处理)。
* **后果**: 过度保护非关键后台服务，同时对核心支付服务保护不足。
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **概率**: 中等 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 客户产品负责人建立服务分级矩阵 (Tier 1/2/3)。
* **责任人**: 应用架构主工程师 | **状态**: 激活 (Active)

---

### 2. 架构与交付 (`RSK-ARC`, `RSK-DEL`)

#### `RSK-ARC-001`: 多工具 CI/CD 集成职责漂移
* **风险陈述**: GitLab、Jenkins 与 Ansible 之间职责重叠可能导致流水线配置漂移及构建失败。
* **类别**: 架构风险
* **原因**: 客户关于同时使用 3 种 CI/CD 工具的硬性指令 (`FUN-002`–`FUN-004`)。
* **后果**: 发布缺乏协调、部署中断及重复的构建步骤。
* **关联需求**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **概率**: 中等 | **影响**: 中等 | **暴露度**: 中等
* **提议缓解措施**: 编写明确的工具边界契约 (GitLab: 触发 $\rightarrow$ Jenkins: 构建 $\rightarrow$ Ansible: 部署)。
* **责任人**: DevOps Lead | **状态**: 激活 (Active)

#### `RSK-ARC-002`: Kubernetes 上托管有状态工作负载的复杂度
* **风险陈述**: 在 EKS 上托管复杂的有状态应用 (RabbitMQ, Nacos, MySQL) 存在 Pod 重新调度期间卷挂载延迟的风险。
* **类别**: 架构风险
* **原因**: Kubernetes Pod 重新调度需要解挂 EBS 卷并跨节点重新挂载。
* **后果**: 节点故障转移期间瞬时的数据库或消息代理停机。
* **关联需求**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md)
* **概率**: 中等 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 在可行的情况下，关键有状态数据库优先选择 AWS 托管服务 (RDS, ElastiCache)。
* **责任人**: 数据架构师 / 基础设施 Lead | **状态**: 激活 (Active)

---

### 3. 安全与访问 (`RSK-SEC`)

#### `RSK-SEC-001`: CI/CD 流水线凭据泄露
* **风险陈述**: 在 Jenkins 构建节点或 GitLab 变量中存储静态 AWS IAM 访问密钥存在密钥泄露风险。
* **类别**: 安全风险
* **原因**: 命令式部署脚本直接调用云 API。
* **后果**: 未经授权访问生产 AWS 基础设施。
* **关联需求**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **概率**: 中等 | **影响**: 严重 | **暴露度**: 高
* **提议缓解措施**: 跨所有 CI/CD 流水线强制执行零静态凭据策略 (`AGENTS.md`)。
* **责任人**: 云安全 Lead | **状态**: 激活 (Active)

#### `RSK-SEC-002`: 过度的 IAM 与 Kubernetes RBAC 权限
* **风险陈述**: 向开发者角色或 Pod 服务账号分配过宽的 IAM 策略 (如 `AdministratorAccess`) 存在安全越权风险。
* **类别**: 安全风险
* **原因**: 出于便利性的开发权限配置。
* **后果**: 未经授权的资源删除或跨 Namespace 权限提升。
* **关联需求**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **概率**: 中等 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 实施 IAM Access Analyzer 及自动化的 RBAC 审计扫描。
* **责任人**: 云安全 Lead | **状态**: 激活 (Active)

#### `RSK-SEC-003`: 跨环境爆炸半径暴露
* **风险陈述**: 测试环境中的越权或误配置传播扩散至生产环境。
* **类别**: 安全风险
* **原因**: 在单个集群或账号中混合部署测试与生产。
* **后果**: 非生产环境操作引发生产停机或客户数据泄露。
* **关联需求**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md)
* **概率**: 低 | **影响**: 严重 | **暴露度**: 中等
* **提议缓解措施**: 阻断测试与生产 VPC 之间的所有 VPC Peering 连接。
* **责任人**: 企业安全 Lead | **状态**: 激活 (Active)

---

### 4. 数据与韧性 (`RSK-DAT`, `RSK-AVL`)

#### `RSK-DAT-001`: Amazon DocumentDB 与 MongoDB 协议不兼容
* **风险陈述**: 若部署在 Amazon DocumentDB 上，使用高级 MongoDB 功能的微服务在运行时可能发生崩溃。
* **类别**: 数据风险
* **原因**: DocumentDB 模拟 MongoDB API，但缺乏完全的语法兼容性（如特定的聚合阶段算子、索引类型）。
* **后果**: 应用数据库驱动运行时错误及微服务查询中断。
* **关联需求**: [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **概率**: 高 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 针对 DocumentDB API 支持矩阵执行自动化的查询兼容性扫描。
* **责任人**: 数据架构主工程师 | **状态**: 激活 (Active)

#### `RSK-DAT-002`: 备份恢复流程未定期演练
* **风险陈述**: 数据库与集群备份损坏或无法恢复，且未被团队发现。
* **类别**: 数据风险
* **原因**: 配置了备份但未安排定期的恢复演练。
* **后果**: 在勒索软件或灾难恢复场景下造成业务数据的完全丢失。
* **关联需求**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **概率**: 中等 | **影响**: 严重 | **暴露度**: 高
* **提议缓解措施**: 安排每月自动化的恢复验证测试，恢复至隔离的测试子网。
* **责任人**: 数据库管理员 / 运维 Lead | **状态**: 激活 (Active)

#### `RSK-AVL-001`: 将 Multi-AZ 高可用误认为是灾难恢复
* **风险陈述**: 误认为 Multi-AZ 部署能够防止完全的区域停机，导致业务连续性未经规划。
* **类别**: 可用性风险
* **原因**: 混淆了本地可用区冗余 (HA) 与跨区域业务连续性 (DR)。
* **后果**: 在 AWS 区域控制平面或物理故障期间，平台完全不可用。
* **关联需求**: [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **概率**: 中等 | **影响**: 严重 | **暴露度**: 高
* **提议缓解措施**: 客户利益相关者书面签署正式的 RTO/RPO 需求与 DR 策略。
* **责任人**: 企业架构师 / 云架构主工程师 | **状态**: 激活 (Active)

---

### 5. 成本与运维 (`RSK-CST`, `RSK-OPS`)

#### `RSK-CST-001`: 托管服务成本激增与过度预置
* **风险陈述**: AWS 托管服务成本 (RDS, ElastiCache, Secrets Manager) 快速增加，超出初始预算。
* **类别**: 成本风险
* **原因**: 在实测工作负载剖析前预置了高规格托管实例。
* **后果**: 月度 AWS 云支出超出预算限制 (`BUS-004`)。
* **关联需求**: [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **概率**: 高 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 配置 AWS Budgets 及带阈值通知的 AWS Cost Anomaly Alerts。
* **责任人**: FinOps Lead | **状态**: 激活 (Active)

#### `RSK-CST-002`: 不受控的可观测性日志写入成本
* **风险陈述**: 应用 Debug 日志或高 Cardinality 指标抓取导致高额的 CloudWatch / OpenSearch 账单激增。
* **类别**: 成本风险
* **原因**: 微服务在生产环境中输出未经过滤的 stdout Debug 日志。
* **后果**: 高额的月度日志写入与存储费用 (`CST-001`)。
* **关联需求**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **概率**: 高 | **影响**: 中等 | **暴露度**: 高
* **提议缓解措施**: 在 Fluent Bit DaemonSet 层强制执行日志级别过滤（生产环境仅限 `INFO`/`WARN`）。
* **责任人**: 运维主工程师 | **状态**: 激活 (Active)

#### `RSK-OPS-001`: 自建中间件沉重的运维负担
* **风险陈述**: 尝试在 EKS 上自建 MySQL、RabbitMQ 和 MongoDB 导致平台 SRE 人员超负荷。
* **类别**: 运维风险
* **原因**: 在缺少足够 DBA 人员的情况下选择开源 Operator 以节省 AWS 托管服务成本。
* **后果**: 由于缺少专业 DBA 响应，在数据库崩溃期间引发系统停机。
* **关联需求**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联 ADRs**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **概率**: 高 | **影响**: 高 | **暴露度**: 高
* **提议缓解措施**: 开展包含 SRE 人力成本在内的正式总体拥有成本 (TCO) 评估。
* **责任人**: DevOps Lead / SRE Lead | **状态**: 激活 (Active)
