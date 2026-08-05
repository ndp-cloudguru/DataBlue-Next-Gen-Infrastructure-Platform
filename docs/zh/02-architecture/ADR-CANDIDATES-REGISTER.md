# ADR 候选决策登记册 (ADR Candidates Register: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档记录了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 在阶段 2 (架构定义阶段) 中确定的所有 **架构决策记录候选方案 (ADR Candidates)**。

根据阶段 2 治理规则：
* 此处标记的决策为 **评估中的临时候选方案**。
* 在阶段 1 权衡打分和正式利益相关者书面签署完成前，任何 ADR 均未最终定稿。

---

## 2. ADR 候选决策日志 (ADR Candidates Log)

| 候选方案 ID | 决策主题 | 评估中的备选方案 | 受影响的需求 | 架构视角 | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ADR-CAN-001` | **环境隔离模型** | **方案 A**: 为测试与生产环境提供独立的 AWS 账号与 EKS 集群。<br>**方案 B**: 采用单个多租户 EKS 集群通过 Namespace 隔离。 | `BUS-003`, `SEC-002`, `NFR-001` | 物理与部署 / 安全 | 建议基线 (方案 A) |
| `ADR-CAN-002` | **有状态中间件架构策略** | **方案 A**: AWS 托管服务 (RDS, ElastiCache, MSK/DocDB)。<br>**方案 B**: EKS 自建中间件 Operator (Bitnami/ECK/KubeBlocks)。 | `FUN-005`–`FUN-009`, `CST-001`, `OPS-001` | 逻辑 / 运维 / FinOps | 评估中 (Under Evaluation) |
| `ADR-CAN-003` | **Kubernetes 节点自动扩缩容选型** | **方案 A**: Karpenter (JIT 即时节点拉起)。<br>**方案 B**: 标准 Kubernetes Cluster Autoscaler (Auto Scaling Groups)。 | `NFR-002`, `CST-001`, `OPS-001` | 运维 / 弹性扩展 | 评估中 (Under Evaluation) |
| `ADR-CAN-004` | **Ingress Controller 架构选型** | **方案 A**: AWS Load Balancer Controller + NGINX Ingress Controller。<br>**方案 B**: AWS VPC Lattice / Gateway API。 | `BUS-001`, `SEC-003`, `OPS-001` | 边缘与 Ingress / 网络 | 评估中 (Under Evaluation) |
| `ADR-CAN-005` | **集群内 Service Mesh 需求** | **方案 A**: 采用 Istio / Linkerd Service Mesh 实现 mTLS 和流量切分。<br>**方案 B**: 原生 AWS VPC CNI + Kubernetes NetworkPolicies。 | `SEC-003`, `OPS-001`, `NFR-002` | 安全 / 逻辑 / 性能 | 评估中 (Under Evaluation) |
| `ADR-CAN-006` | **密钥管理与注入拓扑** | **方案 A**: AWS Secrets Manager + External Secrets Operator (ESO)。<br>**方案 B**: HashiCorp Vault 集群 + Vault Agent Injector。 | `SEC-001`, `FUN-002`–`FUN-004`, `OPS-001` | 安全 & IAM | 评估中 (Under Evaluation) |
| `ADR-CAN-007` | **灾难恢复故障转移模型** | **方案 A**: 多区域冷备 + 代码即基础设施 (IaC) 重新拉起。<br>**方案 B**: 跨区域 Pilot Light 热备 / 暖备集群。 | `NFR-003`, `CST-001` | 韧性 / 运维 / FinOps | 评估中 (Under Evaluation) |
| `ADR-CAN-008` | **边缘安全与 CDN/WAF 选型** | **方案 A**: Cloudflare Enterprise Edge (Cloudflare DNS, CDN, WAF 与 Global Traffic Manager GTM)。<br>**方案 B**: AWS Route 53 + AWS CloudFront + AWS WAF。 | `SEC-002`, `SEC-003`, `NFR-001`, `NFR-003` | 边缘安全 / 网络 / 韧性 | 建议基线 (方案 A) |
