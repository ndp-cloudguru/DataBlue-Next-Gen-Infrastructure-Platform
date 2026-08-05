# ADR-002 — 环境隔离架构模型 (Environment Isolation Model)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 云架构主工程师 (Lead Cloud Architect), 安全工程师 (Security Engineer)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board)
* **关联需求**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-SEC-003` (共享集群爆炸半径), `RSK-SCL-001` (嘈杂邻居资源竞争)
* **关联假设**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 4 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `BUS-003` 规定测试环境与生产环境之间必须实施严格的环境隔离。我们必须决定容器运行时隔离的边界层级（Kubernetes Namespace 隔离 vs. 物理集群隔离 vs. AWS 账号边界隔离）。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **爆炸半径与安全边界**: 消除非生产代码或受攻击 Pod 访问生产数据的风险 (`SEC-002`)。
2. **嘈杂邻居性能保护**: 防止测试环境中的失控 CPU/内存使用或流量高峰影响生产工作负载 (`NFR-001`)。
3. **升级风险隔离**: 允许在测试环境中充分验证 EKS 控制平面和节点 OS 升级，而不会引发生产停机风险。

---

## 3. 约束条件 (Constraints)
* 除非获得正式安全特许，测试与生产环境严禁共享基础设施。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: 单 EKS 集群中的独立 Namespace 隔离
* **描述**: 所有工作负载托管在单个 EKS 集群中，通过 K8s Namespace 和 NetworkPolicies 进行隔离。
* **优势**: 节省控制平面费用 ($0.10/小时)；简化集群管理。
* **劣势**: 共享内核/节点爆炸半径；极高的嘈杂邻居资源抢占风险；零控制平面升级隔离；复杂的 RBAC 管理。
* **安全性影响**: 弱。容器逃逸漏洞将直接暴露生产工作负载。
* **可用性影响**: 弱。共享 etcd 和控制平面故障将同时影响两个环境。

### 方案 2: 单 AWS 账号中的独立 EKS 集群
* **描述**: 在单个 AWS 账号内部创建两个独立的 EKS 集群（测试集群与生产集群）。
* **优势**: 物理 Kubernetes 控制平面与工作节点隔离。
* **劣势**: 共享 AWS IAM 账号边界，存在共享 VPC 路由风险与共享云服务限额。
* **安全性影响**: 中等。良好的 K8s 隔离，但共享 AWS IAM 凭据存在越权访问风险。

### 方案 3: 独立 AWS 账号与独立 EKS 集群 — 推荐方案
* **描述**: 在 `DataBlue-Test-Account` 中托管测试 EKS 集群，在 `DataBlue-Prod-Account` 中托管生产 EKS 集群。
* **优势**: 绝对的安全与网络爆炸半径隔离；零共享基础设施；独立的集群升级生命周期。
* **劣势**: 需要管理多账号 IaC 状态文件。
* **安全性影响**: 最强。零跨环境访问路径。
* **可用性影响**: 最强。完全的故障域隔离。
* **可扩展性影响**: 最强。完全独立的 AWS 资源配额。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: 仅 Namespace | 方案 2: 单账号多集群 | 方案 3: 独立账号与独立集群 |
| :--- | :--- | :--- | :--- |
| **安全爆炸半径** | 弱 | 中等 | **强 (Strong)** |
| **嘈杂邻居保护** | 弱 | 强 | **强 (Strong)** |
| **升级安全性** | 弱 | 强 | **强 (Strong)** |
| **运维风险** | 高 | 中等 | **低 (Low)** |
| **可逆性** | 困难 | 可逆 | **易于扩展/可逆** |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 3: 独立 AWS 账号与独立 EKS 集群架构**。

---

## 7. 决策依据 (Rationale)
方案 3 通过保障测试与生产之间完全的物理、逻辑和身份隔离，严格满足了需求 `BUS-003` 与 `SEC-002`。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 零测试工作负载影响生产性能或安全的风险；安全的集群升级测试。
* **负面影响**: 增加额外的 EKS 控制平面运行费用 (测试集群约 $0.10/小时)。
* **新增运维职责**: 通过 GitOps/IaC 进行双集群生命周期管理。
* **新增风险**: 无。
* **成本影响**: 增加约 $73/月的控制平面开销。

---

## 9. 验证凭证 (Validation Evidence)
* AWS 账号边界审计及 EKS API 终端隔离测试。

## 10. 验收条件 (Acceptance Conditions)
* 企业安全负责人批准。

## 11. 重新评估触发条件 (Revisit Triggers)
* 客户管理层明确指示要求削减非生产 AWS 消费。

## 12. 实施影响 (Implementation Implications)
* 在 Terraform 中按 AWS 账号定义独立的 EKS 集群模块。
