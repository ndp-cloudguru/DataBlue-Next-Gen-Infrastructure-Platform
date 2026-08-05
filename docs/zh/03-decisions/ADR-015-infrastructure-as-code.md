# ADR-015 — 基础设施即代码 (IaC) 架构选型方案 (Infrastructure-as-Code Strategy)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 基础设施主架构师 (Lead Infrastructure Architect), DevOps 负责人 (DevOps Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), 安全团队 (Security Team)
* **关联需求**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`AGENTS.md`](../../AGENTS.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-DEL-001` (IaC 模块复杂度与 State 锁竞争风险)
* **关联假设**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 15 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `BUS-002` 规定了平台自动化部署。`AGENTS.md` 规定了声明式、版本控制的不可变基础设施。我们必须为 AWS Kubernetes 平台选择基础设施即代码 (IaC) 语言、State 状态管理架构及资源拉起模型。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **声明式状态与不可变性**: 100% 的 AWS 基础设施（VPC、子网、IAM Role、EKS 集群、数据库实例）通过代码声明式创建 (`BUS-002`)。
2. **模块化复用与 DRY 原则**: 为测试账号与生产账号创建可复用的基础设施模块 (`ADR-001`, `ADR-002`)。
3. **状态锁与可审计性**: 通过 S3 + DynamoDB 实现远程状态锁定，防止并发执行导致 State 状态文件损坏。

---

## 3. 约束条件 (Constraints)
* 必须在阶段 3 原型设计期间生成干净、版本控制的代码。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: AWS CloudFormation
* **描述**: 使用 AWS 原生的 CloudFormation JSON/YAML 模板。
* **优势**: AWS 原生服务；无需管理远程 State S3 Bucket。
* **劣势**: 冗长、僵硬的 YAML 语法；慢速的执行回滚；弱模块化抽象能力；有限的开源社区模块库。

### 方案 2: AWS Cloud Development Kit (AWS CDK TypeScript/Python)
* **描述**: 使用命令式编程语言 (TypeScript/Python) 编写基础设施，编译为 CloudFormation。
* **优势**: 具表现力的编程语法；面向对象构造复用。
* **劣势**: 命令式代码掩盖了底层基础设施状态；没有软件开发背景的 SRE 维护困难；复杂的 State Diff 审计。

### 方案 3: 纯模块化 Terraform / OpenTofu (云资源 + K8s Manifests)
* **描述**: 使用 HCL 语言配合 Terraform / OpenTofu，通过 Terraform Helm Provider 同时管理 AWS 云资源和集群内部 Kubernetes Helm Release。
* **优势**: 行业标准的 HCL 语法；庞大的开源模块生态；透明的 `terraform plan` Dry-Run 预检 (`AGENTS.md`)。
* **劣势**: 如果开发者同时使用 `kubectl` 应用 Manifests，通过 Terraform Helm Provider 管理 K8s 工作负载可能导致 State 漂移。

### 方案 4: 混合模型 (模块化 Terraform 管理 AWS 云基础设施 + Helm/Ansible/GitOps 管理 K8s 工作负载) — 推荐方案
* **描述**: 清晰的职责分离：
  1. **Terraform / OpenTofu**: 拉起物理 AWS 云基础设施 (VPCs, Subnets, IAM IRSA Roles, EKS Control Plane, Node Groups, KMS Keys, DB Instances)。
  2. **Helm / Ansible / ArgoCD**: 部署集群内部 Kubernetes 应用、Nacos、Operators、Ingress 规则与微服务 (`BUS-002`, `FUN-004`)。
* **优势**: 清晰的运维边界；Terraform 管理云基础设施状态；GitOps / Helm 管理集群内部应用状态，且不会发生 State 文件碰撞。
* **劣势**: 需要管理两个部署层级。
* **安全性影响**: 最强。限定范围的 IAM 执行边界。
* **可逆性**: 易于撤销 (Easily Reversible)。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: CloudFormation | 方案 2: AWS CDK | 方案 3: 纯 Terraform | 方案 4: 混合架构 (Terraform 云 + GitOps K8s) |
| :--- | :--- | :--- | :--- | :--- |
| **声明式清晰度** | 中等 | 弱 (命令式) | **强** | **强 (Strong)** |
| **State 状态边界隔离** | 中等 | 弱 | 中等 | **强 (解耦隔离)** |
| **Dry-Run 预检透明度 (`AGENTS.md`)** | 弱 | 中等 | **强 (`plan`)** | **强 (`plan`)** |
| **开源模块生态** | 中等 | 中等 | **强** | **强 (Strong)** |
| **可逆性** | 困难 | 可逆 | 易于撤销 | **易于撤销 (Easily Reversible)** |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 4: 混合模型** (模块化 Terraform / OpenTofu 管理 AWS 云基础设施 + Helm / Ansible / GitOps 管理 Kubernetes 工作负载)。

---

## 7. 决策依据 (Rationale)
方案 4 建立了清晰的运维边界，将云基础设施状态管理与应用部署逻辑解耦，确保 `terraform plan` 能够提供透明的预检审计，而不会受到瞬态 Pod 部署引发的 State 文件污染 (`AGENTS.md`)。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 清晰的职责分离；透明的 `terraform plan` 输出；测试和生产账号可复用的模块化架构。
* **负面影响**: 需要维护两套运维工具（AWS 采用 Terraform，K8s 采用 Helm/GitOps）。
* **新增运维职责**: 管理远程 S3 Backend State Bucket 和 DynamoDB 锁表。
* **成本影响**: 零软件许可费用。

---

## 9. 验证凭证 (Validation Evidence)
* `terraform plan` Dry-Run 输出校验与远程 S3 Backend State 锁测试。

## 10. 验收条件 (Acceptance Conditions)
* 基础设施 Lead 与 DevOps 负责人签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* 组织强制要求迁移至 AWS 原生 API 控制平面。

## 12. 实施影响 (Implementation Implications)
* 阶段 3 将编写模块化的 Terraform 代码及 S3 Backend 配置文件。
