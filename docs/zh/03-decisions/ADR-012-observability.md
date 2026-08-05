# ADR-012 — 全栈可观测性架构方案 (Observability Architecture Strategy)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 运维主工程师 (Lead Operations Engineer), 云架构师 (Cloud Architect)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), DevOps 负责人 (DevOps Lead)
* **关联需求**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-CST-002` (不受控的可观测性日志存储成本), `RSK-OPS-002` (缺少服务指标 Dashboard)
* **关联假设**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 11 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `OPS-001` 和 `OPS-002` 规定了涵盖约 40 个微服务、Kubernetes 节点与中间件组件的全方位服务器与服务监控、集中式日志聚合以及指标可视化。我们必须选择可观测性技术栈架构，同时控制 AWS 日志存储成本 (`CST-001`)。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **统一的指标与日志可见性**: 为容器指标、节点 CPU/RAM 和应用日志提供统一的单窗口 (Single-Pane-of-Glass) Dashboard (`OPS-001`)。
2. **Kubernetes 与云原生兼容**: 跨微服务和 Nacos 的 Prometheus 指标 Scrape 抓取兼容性 (`OPS-001`)。
3. **日志保留成本治理**: 控制 CloudWatch 日志的高写入与长期存储成本 (`CST-001`, `OPS-002`)。

---

## 3. 约束条件 (Constraints)
* 必须支持测试与生产环境的集中式监控。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: EKS 上纯自建开源 Stack (Prometheus + Grafana + Loki)
* **描述**: 在 EKS 内部部署 Prometheus Operator、Grafana 和 Loki 日志聚合器，使用 EBS 持久卷。
* **优势**: 完全的开源灵活性；零 AWS 单指标写入费用；丰富的 Grafana Dashboard 生态。
* **劣势**: 占用高昂的工作节点 RAM 和 EBS 存储；团队必须自行管理 Prometheus TSDB 存储保留与 Loki 索引扩展。

### 方案 2: AWS Managed Service for Prometheus (AMP) + Managed Grafana (AMG)
* **描述**: 使用 AWS 完全托管的 Prometheus 指标写入与 AWS Managed Grafana 工作空间。
* **优势**: 零服务器管理；无限的指标存储扩展；99.9% 在线率 SLA。
* **劣势**: 写入计费随指标 Sample 线性扩展；对于具有高 Cardinality 的 40 个微服务月度成本极高。

### 方案 3: 纯 AWS CloudWatch 方案
* **描述**: 使用 CloudWatch Container Insights 收集指标，使用 CloudWatch Logs 收集应用日志。
* **优势**: 内置的 AWS 原生集成；无需部署 Helm Chart。
* **劣势**: 专有的 CloudWatch 日志查询语法；高昂的日志写入与指标数据定价；相比 Grafana 缺乏开发者 Dashboard 灵活性。

### 方案 4: 混合架构 (Prometheus/Grafana + Fluent Bit 至 OpenSearch 与 S3) — 推荐方案
* **描述**: 平衡的混合架构：
  1. **EKS 上的 Prometheus Operator + Grafana**: 针对运维 Dashboard 提供高速、本地指标抓取与可视化 (`OPS-001`)。
  2. **Fluent Bit DaemonSet**: 在所有节点上安装轻量级日志转发器。
  3. **Amazon OpenSearch Service**: 实时日志搜索与索引，保留 7-14 天 (`OPS-002`)。
  4. **Amazon S3 生命周期归档**: 原始日志自动导出至 S3 Standard / Glacier，以极低的成本进行长期合规保留 (`CST-001`)。
* **优势**: 提供卓越的 Grafana Dashboard 灵活性；通过归档至 S3 控制日志成本；将日志索引负担从 EKS 节点 RAM 剥离至 OpenSearch。
* **劣势**: 需要配置 Fluent Bit 路由规则及 S3 生命周期策略。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: 纯开源 OSS | 方案 2: AWS AMP/AMG | 方案 3: CloudWatch | 方案 4: 混合架构 |
| :--- | :--- | :--- | :--- | :--- |
| **指标灵活性 (`OPS-001`)** | **强** | **强** | 弱 | **强 (Strong)** |
| **日志成本控制 (`CST-001`)** | 中等 | 中等 | 弱 | **强 (S3 生命周期)** |
| **运维人力** | 沉重 | **极低** | **极低** | 中等 |
| **厂商独立性** | **极高** | 中等 | 低 | **高 (High)** |
| **可逆性** | **易于撤销** | 可逆 | 困难 | **易于撤销** |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 4: 混合架构** (EKS 上的 Prometheus/Grafana + Fluent Bit 转发至 Amazon OpenSearch 与 S3)。

---

## 7. 决策依据 (Rationale)
方案 4 提供了行业标准的 Prometheus/Grafana Dashboard 体验 (`OPS-001`)，通过 OpenSearch 提供实时日志搜索 (`OPS-002`)，并通过利用 S3 Glacier 生命周期规则进行长期日志归档，严格控制了 FinOps 成本 (`CST-001`)。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 100% 满足需求；亚秒级指标 Dashboard；通过 S3 Glacier 实现长期日志存储 80% 的成本节约。
* **负面影响**: 需要维护 Fluent Bit DaemonSet 配置。
* **新增运维职责**: 管理 OpenSearch 集群索引轮转与 S3 生命周期策略。
* **成本影响**: 可预测的 OpenSearch 实例定价 + 极低的 S3 存储开销。
