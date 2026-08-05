# 成本优化与 FinOps 治理规划说明书 (Cost Optimization Plan: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **FinOps 成本优化与治理策略 (FinOps Cost Optimization & Governance Strategy)**。

受需求 [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md)、[`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md) 及 [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md) 治理。

---

## 2. 12 大 FinOps 优化支柱 (12 FinOps Optimization Pillars)

1. **非生产环境自动化夜间缩容**: 定时在非工作时间下调测试 EKS 工作节点（在夜间/周末减少 70% 的节点数量），非生产计算开销可节省约 35%。
2. **Karpenter JIT 即时装箱整理**: 通过将节点规格与 Pod 需求进行动态匹配，消除预先分配的 EC2 Auto Scaling Group 资源浪费 (`ADR-005`)，原始计算资源可节省 15-25%。
3. **EC2 Spot 实例分层混部**: 在测试环境 70% 的计算工作负载中使用 Spot 实例，相比 On-Demand 费率可获得约 70% 的折扣。
4. **Compute Savings Plans 采购**: 在生产基线 EKS 节点上应用 3 年期 Compute Savings Plans，将基线 EC2 成本降低 35-40%。
5. **日志存储生命周期归档**: 通过 Fluent Bit 将原始容器日志流式传输至 S3 Standard，30 天后自动转换为 S3 Glacier 灵活检索 (`ADR-012`)，日志存储成本降低 80%。
6. **生产环境日志级别管控**: 将生产环境中的微服务日志级别严格限定为 `INFO` 和 `WARN`，彻底消除 Debug 日志噪音 (`RSK-CST-002`)。
7. **EBS 卷优化 (`gp3`)**: 采用 `gp3` 存储卷替代旧版 `gp2`，每 GB 成本降低 20%，且具备解耦的基础 IOPS。
8. **跨 AZ 流量削减**: 强制执行 Kubernetes 拓扑分布约束 (Topology Spread Constraints) 及拓扑感知路由 (`topologyKeys`)，将 Pod 到 Pod 的通信保持在同一个可用区内，避免每 GB $0.01 的跨可用区网络费用 (`RSK-003`)。
9. **非生产环境单 NAT 网关**: 为测试 VPC 部署 1 个 NAT 网关而非 3 个 Multi-AZ NAT 网关，每月可节省约 $65 的固定非生产开销。
10. **AWS Secrets Manager ESO 缓存优化**: External Secrets Operator (ESO) 配置为 1 小时刷新间隔，防止产生过度的 Secrets Manager API 调用开销 (`ADR-011`)。
11. **强制性 AWS 资源标签策略**: 通过 AWS Organizations SCPs 强制在 100% 预置的 AWS 资源上添加 `CostCenter`、`Environment`、`BusinessSystem` 及 `Owner` 标签 (`CST-002`)。
12. **AWS Budgets 与成本异常告警**: 配置 AWS Budgets，在达到月度预算预测 85% 时触发 Slack/邮件通知，配置 AWS Cost Anomaly Detection，在日消费意外激增超过 20% 时实时告警。
