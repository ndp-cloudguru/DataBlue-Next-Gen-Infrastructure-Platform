# 测试凭证主登记册说明书 (Test Evidence Register: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **Master 测试凭证主登记册 (Master Test Evidence Register)**。

根据阶段 5 治理规则：
* **在未将验证通过的实测凭证附在此登记册上的情况下，严禁授予任何门槛批准 ([`GATE-01`](../04-planning/ACCEPTANCE-GATES.md) 至 [`GATE-10`](../04-planning/ACCEPTANCE-GATES.md))**。
* 每一项凭证均需要包含物理构件路径、执行时间戳、SHA-256 哈希值、负责工程师及验证状态。

---

## 2. Master 测试凭证主目录 (Master Test Evidence Catalog)

| 凭证 ID | 目标验收门槛 | 凭证构件描述 | 所需构件格式 / 文件类型 | 负责工程师 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`EVD-EVD-001`** | [`GATE-01`](../04-planning/ACCEPTANCE-GATES.md) | 工作负载凭证剖析报告 (CPU/RAM/IOPS) | `profiling_report.pdf` | 云架构主工程师 | `待定 (Pending)` |
| **`EVD-ENV-001`** | [`GATE-04`](../04-planning/ACCEPTANCE-GATES.md) | AWS Landing Zone 账号与 VPC 隔离审计 | `landing_zone_audit.json` | 云安全 Lead | `待定 (Pending)` |
| **`EVD-K8S-001`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | Sonobuoy EKS Kubernetes 一致性测试输出 | `sonobuoy_results.tar.gz` | 基础设施架构师 | `待定 (Pending)` |
| **`EVD-ING-001`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | SSL Labs A 级评级 Ingress TLS 证书扫描 | `ssl_labs_scan.pdf` | DevOps 工程师 | `待定 (Pending)` |
| **`EVD-SEC-001`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | Trivy 容器漏洞扫描报告 (0 严重漏洞) | `trivy_scan_report.json` | 云安全 Lead | `待定 (Pending)` |
| **`EVD-SEC-002`** | [`GATE-05`](../04-planning/ACCEPTANCE-GATES.md) | IAM Access Analyzer 最小权限审计 (0 通配符 `*`) | `iam_policy_audit.json` | 云安全 Lead | `待定 (Pending)` |
| **`EVD-SCL-001`** | [`GATE-06`](../04-planning/ACCEPTANCE-GATES.md) | Karpenter 节点自动扩缩容基准测试 (< 60s) | `karpenter_scale_metrics.csv` | SRE Lead | `待定 (Pending)` |
| **`EVD-PRF-001`** | [`GATE-06`](../04-planning/ACCEPTANCE-GATES.md) | 技术试点压力测试报告 (Locust/k6) | `k6_benchmark_report.html` | 性能 Lead | `待定 (Pending)` |
| **`EVD-CAB-001`** | [`GATE-07`](../04-planning/ACCEPTANCE-GATES.md) | 变更咨询委员会 (CAB) 签署的授权 Ticket | `cab_release_ticket.pdf` | 项目发起人 | `待定 (Pending)` |
| **`EVD-DB-001`** | [`GATE-08`](../04-planning/ACCEPTANCE-GATES.md) | RDS MySQL 30 天 PITR 快照恢复验证 | `rds_pitr_restore_log.txt` | DBA Lead | `待定 (Pending)` |
| **`EVD-HA-001`** | [`GATE-08`](../04-planning/ACCEPTANCE-GATES.md) | Chaos Mesh 可用区停机与节点终止演练日志 | `chaos_failover_log.txt` | SRE Lead | `待定 (Pending)` |
| **`EVD-DR-001`** | [`GATE-08`](../04-planning/ACCEPTANCE-GATES.md) | 区域灾难恢复演练 RTO/RPO SLA 测试日志 | `dr_failover_drill.log` | 云架构主工程师 | `待定 (Pending)` |
| **`EVD-WAV-001`** | [`GATE-09`](../04-planning/ACCEPTANCE-GATES.md) | 应用上线波次签署证书 | `wave_1_5_signoff.pdf` | 迁移 Lead | `待定 (Pending)` |
| **`EVD-CST-001`** | [`GATE-10`](../04-planning/ACCEPTANCE-GATES.md) | FinOps 资源标签合规性报告 (100%) | `aws_cost_tag_audit.csv` | FinOps Lead | `待定 (Pending)` |
| **`EVD-OPS-001`** | [`GATE-10`](../04-planning/ACCEPTANCE-GATES.md) | 签署的运维支持交接证书 | `handover_certificate.pdf` | 运维 Lead | `待定 (Pending)` |

---

## 3. 凭证存储与完整性治理 (Evidence Storage & Integrity Governance)

1. **存储位置**: 所有原始测试凭证文件必须上传至安全账号内部加密的 S3 凭证 Vault 存储桶 (`s3://databue-test-evidence-vault/`)。
2. **不可变策略**: 在凭证存储桶上启用 Object Lock，防止删除或修改验证凭证。
3. **可追溯性绑定**: 凭证 IDs (`EVD-xxx`) 必须在 [`REQUIREMENT-TRACEABILITY-MATRIX.md`](REQUIREMENT-TRACEABILITY-MATRIX.md) 内部进行交叉引用。
