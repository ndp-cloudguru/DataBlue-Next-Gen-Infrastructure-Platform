# 实施风险管控规划说明书 (Implementation Risk Plan: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档将所有识别出的风险描述 (`RISK-REGISTER.md`) 直接映射到 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 11 个交付阶段中。

文档重点强调了在进入阶段 7（生产环境平台建设）之前必须完全解决的关键 **生产阻断项 (Production Blockers)**。

---

## 2. 逐阶段实施风险映射表 (Phase-by-Phase Implementation Risk Mapping)

| 阶段 | 阶段名称 | 主要关联风险 | 缓解控制措施与门槛 | 是否生产阻断项？ |
| :--- | :--- | :--- | :--- | :--- |
| **阶段 0** | **凭证收集与剖析** | `RSK-UNC-001`, `RSK-UNC-002`, `RSK-DAT-001`, `RSK-UNC-003` | 工作负载剖析、DocumentDB 查询审计、BCP 签署 ([`GATE-01`](ACCEPTANCE-GATES.md))。 | **是 (严重阻断项)** |
| **阶段 1** | **AWS 基础建设** | `RSK-SEC-003`, `RSK-CST-001` | Landing Zone 多账号隔离、KMS 加密 ([`GATE-04`](ACCEPTANCE-GATES.md))。 | **是** |
| **阶段 2** | **测试平台建设** | `RSK-OPS-001`, `RSK-SCL-001` | 专有测试 EKS 集群、IRSA 身份绑定 ([`GATE-05`](ACCEPTANCE-GATES.md))。 | 否 |
| **阶段 3** | **共享平台服务** | `RSK-SEC-001`, `RSK-CST-002`, `RSK-DAT-002` | ArgoCD GitOps, ESO 密钥同步, Fluent Bit S3 生命周期。 | 否 |
| **阶段 4** | **CI/CD 集成** | `RSK-ARC-001`, `RSK-SEC-001` | 混合覆盖模型、零静态 Git 凭据策略。 | 否 |
| **阶段 5** | **中间件交付** | `RSK-OPS-001`, `RSK-ARC-002` | 多可用区数据库故障转移、Nacos Raft 集群、30 天 PITR。 | **是** |
| **阶段 6** | **技术试点上线** | `RSK-SCL-001`, `RSK-CST-001` | 压力负载测试、Karpenter < 60s 节点扩容 ([`GATE-06`](ACCEPTANCE-GATES.md))。 | **是** |
| **阶段 7** | **生产平台建设** | `RSK-SEC-003`, `RSK-DAT-002` | CAB 批准签署 ([`GATE-07`](ACCEPTANCE-GATES.md))、AWS Backup Vault Lock。 | **是** |
| **阶段 8** | **应用波次迁移** | `RSK-DEL-001`, `RSK-SEC-001` | 波次准入/准出标准、自动化 ArgoCD 回滚 ([`GATE-09`](ACCEPTANCE-GATES.md))。 | 否 |
| **阶段 9** | **生产就绪与 DR** | `RSK-AVL-001`, `RSK-DAT-002` | Chaos Mesh 节点崩溃、模拟 AZ 停机、DR 演练 ([`GATE-08`](ACCEPTANCE-GATES.md))。 | **是** |
| **阶段 10**| **运维交接** | `RSK-OPS-001`, `RSK-OPS-002` | Runbook 交付、SRE 培训、权限交接 ([`GATE-10`](ACCEPTANCE-GATES.md))。 | 否 |

---

## 3. 生产阻断项汇总 (Production Blocker Summary)

在获得 CAB 批准签署 ([`GATE-07`](ACCEPTANCE-GATES.md)) 以拉起 `DataBlue-Prod-Account` 之前，必须完全解决以下 5 个风险项：
1. `RSK-UNC-001` (微服务容量剖析数据被完整收集并验证)。
2. `RSK-DAT-001` (完成 DocumentDB 兼容性审计)。
3. `RSK-UNC-003` (业务 RTO/RPO SLA 目标获得正式书面签署)。
4. `RSK-SEC-003` (多账号隔离得到验证，不存在跨账号 VPC Peering 滥用)。
5. `RSK-SCL-001` (技术试点负载基准测试在 [`GATE-06`](ACCEPTANCE-GATES.md) 获得通过)。
