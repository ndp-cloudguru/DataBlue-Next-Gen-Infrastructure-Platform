# 运维支持就绪规划说明书 (Support Readiness Plan: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了将 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 从项目实施阶段平滑过渡至长期 **运维支持阶段 (Operational Support)** 的强制性要求、检查清单及交接协议。

受 [`GATE-10`](../04-planning/ACCEPTANCE-GATES.md) (交接验收) 治理。

---

## 2. 运维支持过渡检查清单 (Support Transition Checklist)

| 类别 | 就绪验证检查项 | 负责角色 | 通过标准 | 状态 |
| :--- | :--- | :--- | :--- | :--- |
| **Runbooks** | 为 100% 的 PagerDuty 告警编写运维 Runbooks | DevOps Lead | 验证通过步骤明确的修复流程 | 待定 (Pending) |
| **可观测性**| 100% 的微服务指标渲染在 Grafana 中 | SRE Lead | 单窗口 (Single-Pane-of-Glass) Dashboard 激活 | 待定 (Pending) |
| **日志** | OpenSearch 集中日志搜索激活并配置 S3 Glacier 归档 | Operations Lead | 验证通过 7 天热搜索 + S3 导出 | 待定 (Pending) |
| **备份** | Velero 及数据库 PITR 自动化恢复完成验证 | DBA Lead | 每月执行恢复测试 ([`GATE-08`](../04-planning/ACCEPTANCE-GATES.md)) | 待定 (Pending) |
| **DR 演练** | 跨区域 DR 故障转移演练成功执行 | Cloud Architect | 在备用区域满足 RTO & RPO SLAs | 待定 (Pending) |
| **安全** | 100% 的 IAM 策略验证符合最小权限 (0 通配符 `*`) | Security Lead | IAM Access Analyzer 审计通过 | 待定 (Pending) |
| **培训** | 100% 的 SRE 值班工程师接受平台运维培训 | SRE Lead | 签署培训完成确认书 | 待定 (Pending) |
| **权限** | 通过 IAM Identity Center SSO 授予生产访问权限 | Security Lead | 零静态 SSH/AWS 密钥凭据 | 待定 (Pending) |
| **FinOps** | 100% 的 AWS 资源完成成本分摊标签验证 | FinOps Lead | AWS Cost Explorer 成本分摊校验完毕 | 待定 (Pending) |

---

## 3. 运维交接签署 (Operational Handover Sign-Off)

在完成上述 100% 的检查清单项后，通过签署 **运维交接证书 (Operational Handover Certificate)** 完成正式交接：

```markdown
### 运维交接证书 (Operational Handover Certificate)
* **平台名称**: DataBlue 下一代基础设施平台 (`datablue-nextgen-infra-platform`)
* **项目交付 Lead**: `[签名与日期]`
* **企业运维 / SRE Lead**: `[签名与日期]`
* **项目发起人 (Project Sponsor)**: `[签名与日期]`
```
