# 非功能性需求规范 (Non-Functional Requirements: DataBlue Next-Gen Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的目标质量属性、运维约束以及非功能性需求 (NFR)。

在缺少客户具体数字性能指标、SLA 或容量基准的情况下，相关目标显式标记为 **`TBD` (待确定)**，并附有确定最终阈值所需实证数据的明确说明。

---

## 2. 技术质量属性 (Technical Quality Attributes)

### 2.1 可用性 (Availability)
* **多可用区控制平面与节点拓扑 (Multi-AZ Topology)**: EKS 控制平面（由 AWS 在 3 个可用区托管）及工作节点必须在 AWS 目标区域内的至少 3 个可用区 (3 AZs) 间保持跨区活动分布。
* **目标平台在线率 SLA**: **`TBD`**
  * *所需凭证*: 各业务系统层级的业务 SLA 需求。建议基线目标为生产环境 ≥99.9%，测试环境 ≥99.0%。
* **单点故障 (SPOF)**: 生产环境计算、网络、Ingress (AWS ALB) 及有状态中间件架构中，不允许存在任何单点故障。

---

### 2.2 可扩展性 (Scalability)
系统扩展必须明确解耦为三个独立的层级：

1. **Kubernetes 应用级扩展 (Pod 动态扩缩容)**:
   * **机制**: 基于 CPU/Memory 利用率的 Horizontal Pod Autoscaler (HPA)，结合 KEDA（基于事件驱动的 Autoscaler）监控 RabbitMQ 队列深度。
   * **目标响应时间窗口**: **`TBD`**
   * *所需凭证*: 微服务启动延迟分析与压测突发流量指标。

2. **Kubernetes 节点级扩展 (集群基础设施扩缩容)**:
   * **机制**: Karpenter 或 Cluster Autoscaler 动态创建 EC2 实例（非生产环境混合使用 On-Demand 与 Spot 实例）。
   * **目标节点拉起时间**: **`TBD`**
   * *所需凭证*: 使用预热 AMI / Bottlerocket OS 的节点启动时间基准测试。

3. **数据库与中间件扩展**:
   * **机制**: 关系型数据库只读副本剥离 (MySQL)、Redis 集群分片、MongoDB 副本集扩展。
   * **目标连接数与 IOPS 上限**: **`TBD`**
   * *所需凭证*: 数据库读写比例分析及微服务连接池剖析。

---

### 2.3 性能 (Performance)
* **API Ingress 延迟 (P95 / P99)**: **`TBD`**
  * *所需凭证*: 客户性能基线或 SLA 合同需求（例如在 AWS ALB 边界 P95 延迟 < 200ms）。
* **吞吐量能力 (峰值 RPS)**: **`TBD`**
  * *所需凭证*: 业务高峰期 5–6 个业务系统的交易量指标。
* **存储 IOPS 与延迟**: 数据库存储配置预置 IOPS (gp3/io2)，保持读写延迟 < 5ms。

---

### 2.4 安全性与访问控制 (Security & Access Control)
* **最小权限身份与访问管理 (IAM & RBAC)**:
  * 专有使用 AWS IAM Roles for Service Accounts (IRSA) 提供 Pod 级的 AWS API 访问权限（零硬编码 AWS 凭证）。
  * Kubernetes RBAC 与企业 SSO/OIDC 集成，用于运维人员的集群访问控制。
* **网络隔离与边界安全**:
  * 测试与生产工作负载隔离到独立的 AWS 账号中。
  * Kubernetes NetworkPolicies 强制执行微服务间默认拒绝 (Default-Deny) 入站/出站规则。
  * AWS Security Groups 在网络边界实施严格的端口过滤。
* **加密基线**:
  * 静态数据 (Data at Rest): 在 EBS、RDS、ElastiCache、S3 及 EKS Secrets (etcd) 上使用客户托管的 AWS KMS 密钥加密。
  * 传输中数据 (Data in Transit): 所有公网 API Ingress 终端强制使用 TLS 1.3，集群内部微服务通信使用 TLS 1.2+。

---

### 2.5 可恢复性 (Recoverability)
业务连续性的解耦定义：

* **高可用 (HA)**: 多可用区冗余，在单个实例、Pod 或可用区故障时提供无缝持续运行。目标 RTO = 0（无感故障转移）。
* **时间点备份 (Point-in-Time Backup)**: MySQL、MongoDB、Redis 和 etcd 的自动化每日快照生命周期策略，并跨区域复制到 S3。目标保留期 = 30 天。
* **灾难恢复 (DR)**:
  * **目标 RTO (恢复时间目标)**: **`TBD`**
  * **目标 RPO (恢复点目标)**: **`TBD`**
  * *所需凭证*: 正式的业务连续性计划 (BCP) 签署文件，详细指定 AWS 区域彻底故障时可接受的数据丢失与停机时间。

---

### 2.6 可观测性与服务监控 (Observability & Monitoring)
* **指标与监控**: 通过 Prometheus/Grafana 或 AWS CloudWatch Container Insights 持续收集节点、容器、Pod、Ingress 和中间件指标。
* **集中式日志**: 应用 stdout/stderr、API Ingress 日志和审计日志转发至 Amazon OpenSearch / CloudWatch，配置自动归档。
* **分布式追踪**: OpenTelemetry / AWS X-Ray 追踪集成，实现约 40 个微服务的请求流可视化。
* **告警 SLA**: 关键指标阈值突破（如节点故障、Pod 崩溃循环、存储 > 85%）时，< 2 分钟内自动触发 PagerDuty / Slack 告警。

---

### 2.7 可维护性与代码即基础设施 (IaC)
* **不可变基础设施 (Immutable Infrastructure)**: 100% 的 AWS 基础设施通过模块化、版本控制的 Terraform / OpenTofu 模块创建。生产环境中禁止手动控制台修改。
* **声明式 GitOps 部署**: EKS 集群工作负载通过 GitOps 流水线进行声明式管理。
* **零停机平台升级**: EKS 集群与工作节点 OS 更新通过蓝绿 Node Pool 轮转替换执行，业务无感知。

---

### 2.8 成本控制与 FinOps 治理 (Cost Control & FinOps)
* **强制性资源标签策略**: 100% 的 AWS 资源标记 `Environment` (`Test`/`Prod`), `BusinessSystem`, `CostCenter`, `ManagedBy` (`Terraform`), 和 `Owner`。
* **成本分摊追踪**: 启用基于业务系统与环境的 AWS Cost Explorer 自动细分。
* **非生产环境自动缩容**: 非生产环境（测试）在非工作时间（夜间/周末）配置自动缩容减配。
* **成本异常检测**: 配置 AWS Cost Anomaly Detection，在未预期消费激增超过基线 20% 时，24 小时内通知 FinOps 负责人。
