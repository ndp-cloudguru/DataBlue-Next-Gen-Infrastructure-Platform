# ADR-003 — Kubernetes 容器编排平台选型 (Kubernetes Platform Engine)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 云架构主工程师 (Lead Cloud Architect), DevOps 负责人 (DevOps Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board)
* **关联需求**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-OPS-001` (控制平面运维维护开销)
* **关联假设**: [`ASM-003`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 6 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
平台需要一个生产级的 Kubernetes 容器运行时来编排约 40 个微服务 (`FUN-001`)。我们必须选择底层 Kubernetes 控制平面的部署与管理引擎。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **控制平面韧性与可用性**: 保障多可用区 (Multi-AZ) 控制平面在线率，无需人工进行复杂的 etcd Quorum 仲裁管理 (`NFR-001`)。
2. **AWS 原生服务集成**: 与 AWS IAM (IRSA), VPC CNI, AWS KMS 以及 AWS ALB Ingress Controller 无缝集成 (`SEC-001`)。
3. **运维维护开销**: 最大程度降低团队在控制平面补丁升级、Master 节点 OS 升级以及备份/恢复所需的运维开销。

---

## 3. 约束条件 (Constraints)
* 基础设施必须在 AWS 云生态上原生创建。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: EC2 上自建 Kubernetes (kOps / kubeadm)
* **描述**: 使用 kOps 或 kubeadm 脚本手动部署和管理 etcd 节点及 API Server Master EC2 实例。
* **优势**: 节省 EKS 控制平面费用 ($0.10/小时)；拥有对 Kubernetes API Server 参数标志的完全访问权限。
* **劣势**: 极高的运维复杂度；团队必须自行管理 etcd Quorum 备份、OS 补丁更新、控制平面多可用区故障转移及手动升级。
* **安全性影响**: 高风险。未打补丁的控制平面漏洞或未加密配置的 etcd。
* **可用性影响**: 中等至较弱。除非有专门的 SRE 团队维护 24/7 的 etcd 仲裁监控。
* **可扩展性影响**: 集群高负载期间需要手动调整 Master 节点规格。
* **运维影响**: 沉重的日常人力成本与运维负担 (`RSK-OPS-001`)。
* **成本影响**: 节省约 $73/月的控制平面开销，但显著增加了 SRE 人力成本。
* **厂商绑定**: 低。
* **迁移复杂度**: 高。
* **可逆性**: 困难。

### 方案 2: Amazon EKS (AWS 托管 Kubernetes 控制平面) — 推荐方案
* **描述**: 使用 Amazon EKS，由 AWS 完全托管控制平面可用性、etcd 加密以及多可用区 Master 节点弹性扩展。
* **优势**: 99.95% SLA 承诺的控制平面在线率；自动化 etcd 管理；原生 AWS IAM IRSA 集成；托管节点组 (Managed Node Groups) 能力。
* **劣势**: 每个集群约 $0.10/小时 ($73/月) 的控制平面费用；AWS 控制 Master 节点版本的升级节奏。
* **安全性影响**: 极佳。集成了 AWS KMS etcd 加密与 IAM OIDC 身份认证 (`SEC-001`)。
* **可用性影响**: 极佳。自动创建多可用区 Active-Active 控制平面。
* **可扩展性影响**: 极佳。控制平面根据 API 请求吞吐量自动弹性扩展。
* **运维影响**: 控制平面维护开销极低。
* **成本影响**: 可预测的每个集群 $0.10/小时固定费用。
* **厂商绑定**: 中等 (AWS EKS 原生集成)。
* **迁移复杂度**: 低 (标准 upstream Kubernetes API 兼容)。
* **可逆性**: 易于撤销/迁移。

### 方案 3: 其他托管平台 (AWS 上的 Red Hat OpenShift - ROSA)
* **描述**: 运行在 AWS 基础设施上的托管 Red Hat OpenShift 平台。
* **优势**: 企业级开发者门户、内置 CI/CD 流水线以及开箱即用的 Service Mesh。
* **劣势**: 极其昂贵的授权费用 (Red Hat 订阅费)；平台强约束性。
* **安全性影响**: 强企业合规能力。
* **可用性影响**: 高。由 AWS 和 Red Hat 共同托管。
* **成本影响**: 相比标准 EKS，软件许可成本极高。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: EC2 自建 K8s | 方案 2: Amazon EKS | 方案 3: Red Hat ROSA |
| :--- | :--- | :--- | :--- |
| **控制平面 HA & SLA** | 弱 | **强 (Strong)** | **强 (Strong)** |
| **AWS IAM / VPC 集成** | 中等 | **强 (Strong)** | 中等 |
| **运维简易度** | 弱 | **强 (Strong)** | 中等 |
| **成本效益** | 中等 (高人力) | **强 (Strong)** | 弱 (高许可) |
| **可逆性** | 困难 | **易于扩展/可逆** | 困难 |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 2: Amazon EKS (AWS 托管 Kubernetes 控制平面)**。

---

## 7. 决策依据 (Rationale)
Amazon EKS 彻底消除了控制平面的运维开销 (`RSK-OPS-001`)，提供原生的 AWS IAM/VPC 集成，并以其他商业替代方案一小部分的成本提供标准的 upstream Kubernetes API 兼容性。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 99.95% 控制平面 SLA；极低 SRE 维护人力；原生 IRSA 集成。
* **负面影响**: 每个环境集群 $0.10/小时的控制平面费用。
* **新增运维职责**: 跟踪 AWS EKS 版本支持生命周期，规划年度集群升级。
* **新增风险**: EKS API 版本废弃周期。
* **成本影响**: 测试 + 生产控制平面管理费合计约 $146/月。

---

## 9. 验证凭证 (Validation Evidence)
* AWS EKS 服务 SLA 文档及 IAM OIDC IRSA 集成审计。

## 10. 验收条件 (Acceptance Conditions)
* 企业架构委员会签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* EKS 控制平面成本模型发生改变或出现多云可移植性强制需求。

## 12. 实施影响 (Implementation Implications)
* 阶段 3 将通过标准的 Terraform EKS 模块拉起 EKS 控制平面。
