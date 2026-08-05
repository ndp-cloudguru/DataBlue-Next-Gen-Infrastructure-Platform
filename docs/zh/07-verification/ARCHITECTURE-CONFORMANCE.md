# 架构一致性审计说明书 (Architecture Conformance Audit: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **架构一致性审计框架 (Architecture Conformance Audit Framework)**。

文档用于验证物理 AWS 基础设施的部署和 EKS 集群配置是否严格符合批准的 [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 及 15 个架构决策记录 ([`ADR-REGISTER.md`](../03-decisions/ADR-REGISTER.md))。

---

## 2. ADR 架构一致性审计矩阵 (ADR Architecture Conformance Audit Matrix)

| ADR ID | 架构决策主题 | 目标一致性规范 | 自动化审计检查方法 | 负责审计员 | 一致性状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`ADR-001`** | AWS Landing Zone 多账号 | 独立的 `Test`, `Prod`, `Shared`, `Security` 账号 | AWS Organizations API 与 Control Tower 审计 | 云安全 Lead | `待定 (Pending)` |
| **`ADR-002`** | 环境与集群隔离 | 测试与生产之间零共享 EKS 集群或 VPC Peering | AWS VPC 路由表与 IAM 边界审计 | 基础设施架构师 | `待定 (Pending)` |
| **`ADR-003`** | Kubernetes 引擎选型 | 跨 3 个可用区部署的托管 EKS (`v1.30+`) | Sonobuoy Kubernetes 一致性测试套件 | 云架构主工程师 | `待定 (Pending)` |
| **`ADR-004`** | CI/CD 混合工具链 | GitLab + Jenkins + Ansible + ArgoCD GitOps 同步 | 流水线 Dry-Run 执行测试 | DevOps Lead | `待定 (Pending)` |
| **`ADR-005`** | 节点自动扩缩容引擎 | Karpenter JIT NodePools (Spot/On-Demand 混部) | Pod 调度压力测试 (< 60s 节点拉起) | SRE Lead | `待定 (Pending)` |
| **`ADR-006`** | 关系型数据库 (MySQL) | Multi-AZ 主/备部署 | AWS RDS API Multi-AZ 验证 | DBA Lead | `暂缓 (待阶段 0)` |
| **`ADR-007`** | 内存级缓存 (Redis) | Multi-AZ ElastiCache 复制组 | Redis INFO 复制节点审计 | DBA Lead | `暂缓 (待阶段 0)` |
| **`ADR-008`** | 消息代理 (RabbitMQ) | 跨 3 可用区的 3 节点 Quorum 队列 | RabbitMQ Management API Quorum 审计 | 应用架构主工程师 | `暂缓 (待阶段 0)` |
| **`ADR-009`** | 文档数据库 (MongoDB) | 跨 3 可用区的 3 成员副本集 | MongoDB `rs.status()` 审计 | DBA Lead | `暂缓 (待阶段 0)` |
| **`ADR-010`** | Nacos 服务发现与配置 | EKS 上基于 MySQL 的 3 节点 Raft 集群 | Nacos Naming API 集群状态审计 | 应用架构主工程师 | `待定 (Pending)` |
| **`ADR-011`** | 密钥管理架构 | AWS Secrets Manager + External Secrets Operator | ESO ClusterSecretStore 同步测试 | 安全工程师 | `待定 (Pending)` |
| **`ADR-012`** | 可观测性平台 | Prometheus/Grafana + Fluent Bit 至 OpenSearch & S3 | 指标 Scrape 抓取与日志索引验证 | 运维 Lead | `待定 (Pending)` |
| **`ADR-013`** | 备份策略与保留 | 30 天数据库 PITR + Velero S3 快照 | Velero 备份恢复演练测试 | 存储 Lead | `待定 (Pending)` |
| **`ADR-014`** | 灾难恢复策略 | 区域故障转移 (Pilot Light / 待命) | 区域 DR 故障转移演练执行 | 云架构主工程师 | `暂缓 (待 SLA)` |
| **`ADR-015`** | 基础设施即代码 (IaC) | 模块化 Terraform / OpenTofu (远程 S3 State) | `checkov` & `tflint` 静态分析扫描 | 基础设施 Lead | `待定 (Pending)` |

---

## 3. 架构漂移检测协议 (Architecture Drift Detection Protocol)

1. **每日基础设施漂移扫描**: 在 CI/CD 流水线中每晚定时执行自动化的 Terraform Plan 检查 (`terraform plan -detailed-exitcode`) (`FUN-004`)。
2. **集群 Manifest 漂移扫描**: ArgoCD GitOps Controller 设置为 Auto-Sync 自动同步模式，并在出现 Out-of-Sync 离步时发送 Slack 告警通知 (`ADR-004`)。
3. **漂移修复 SLA**: 任何检测到的未经批准的架构漂移必须在 1 小时内自动还原恢复。
