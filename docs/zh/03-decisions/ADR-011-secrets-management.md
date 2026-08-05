# ADR-011 — 密钥与敏感信息管理架构拓扑 (Secrets Management Topology)

## 元数据 (Metadata)
* **状态**: `待审查 (Proposed)`
* **日期**: 2026-08-03
* **决策负责人**: 云安全 Lead (Cloud Security Lead), DevOps 负责人 (DevOps Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board)
* **关联需求**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-SEC-001` (CI/CD 流水线凭据泄露风险), `RSK-SEC-002` (etcd 中未加密密钥风险)
* **关联假设**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 7 节, 第 8 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `SEC-001` 规定了集中式的访问与权限管理，严禁在代码仓库或容器镜像中存储任何静态凭据。我们必须选择一个企业级的密钥管理架构，以便将数据库密码、API Token 和证书安全注入到测试和生产环境的微服务 Pod 中。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **零静态凭据**: 消除 Git 仓库、CI/CD 流水线或容器镜像中的硬编码密码 (`SEC-001`)。
2. **KMS 信封加密与审计追踪**: 持续的密钥自动轮转、AWS KMS 信封加密以及 CloudTrail 审计日志。
3. **运维开销与 Kubernetes 集成**: 原生同步至 Kubernetes Secrets，无需在每个 Pod 中挂载复杂的 Sidecar 容器。

---

## 3. 约束条件 (Constraints)
* 密钥注入必须原生支持 EKS IAM Roles for Service Accounts (IRSA)。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: 原生 Kubernetes Secrets (Base64 编码)
* **描述**: 直接将应用密钥存储为 etcd 中的原生 Kubernetes Secret 对象。
* **优势**: Kubernetes 原生内置；简单的 Manifest 语法。
* **劣势**: Base64 编码并非加密；密钥极易被意外提交至 Git 仓库；缺乏自动化的密钥轮转或集中式审计日志。
* **安全性影响**: 弱。向任何拥有 Namespace 读取权限的人员明文暴露密钥。
* **相关风险**: `RSK-SEC-002` (Git 仓库或 etcd 备份中的明文凭据泄露风险)。

### 方案 2: AWS Secrets Manager + External Secrets Operator (ESO) — 推荐方案
* **描述**: 在 AWS Secrets Manager 中集中管理 Master 密钥（通过 AWS KMS 加密），并由开源的 External Secrets Operator (ESO) 自动同步为 EKS 内部的瞬态 Kubernetes Secrets。
* **优势**: 集中式 AWS CloudTrail 审计日志；自动化的 KMS 密钥轮转；ESO 使用 IAM IRSA OIDC 身份认证 (`SEC-001`)；零 Sidecar 延迟开销。
* **劣势**: AWS Secrets Manager API 费用（$0.40/密钥/月 + $0.05 / 1万次 API 调用）。
* **安全性影响**: 极佳。KMS 信封加密 + 按环境账号严格限定的 IAM 策略。
* **运维影响**: 运维维护开销极低（将密钥库维护工作托付给 AWS）。
* **成本影响**: 可预测的极低月度开销（总计约 $20-50/月）。

### 方案 3: HashiCorp Vault 集群 (EKS 自建或 Vault 托管版)
* **描述**: 部署专有的 3 节点 HashiCorp Vault 集群，配合 Vault Agent Injector Sidecar 容器。
* **优势**: 多云可移植性；动态密钥生成（瞬态数据库凭据）。
* **劣势**: 极其昂贵的运维复杂度；Unseal 解锁密钥管理；每个 Pod 上的 Sidecar 内存/CPU 开销；需要企业级功能时高昂的许可费用。
* **运维影响**: 平台团队面临沉重的运维负担。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: 原生 K8s Secrets | 方案 2: AWS Secrets Manager + ESO | 方案 3: HashiCorp Vault |
| :--- | :--- | :--- | :--- |
| **安全与 KMS 加密** | 弱 | **强 (Strong)** | **强 (Strong)** |
| **审计追踪 (`SEC-001`)** | 弱 | **强 (CloudTrail)** | 强 (Vault Audit) |
| **运维简易度** | 高 | **高 (AWS 托管)** | 弱 (高开销) |
| **成本效益** | 高 | **高 (High)** | 低 |
| **可逆性** | 易于撤销 | **可逆 (Reversible)** | 困难 |

---

## 6. 提议决策 (Proposed Decision)
**最终选择方案 2: AWS Secrets Manager + External Secrets Operator (ESO)**。

---

## 7. 决策依据 (Rationale)
方案 2 强制执行最小权限安全策略 (`SEC-001`)，提供不可变的 AWS CloudTrail 审计日志，并将密钥库维护托付给 AWS，避免了 HashiCorp Vault 沉重的运维负担，同时彻底消除了 Git 仓库中静态明文凭据的风险。

---

## 8. 后果与影响 (Consequences)
* **积极影响**: 100% 合规最小权限 IAM IRSA 策略；自动化的密钥轮转；零静态 Git 凭据。
* **负面影响**: AWS Secrets Manager 每月产生的标称 API 成本 (约 $20-50/月)。
* **新增运维职责**: 管理 ExternalSecrets 自定义资源，设置恰当的同步刷新间隔。
* **新增风险**: 如果刷新间隔设置为 1 分钟以下，可能面临 Secrets Manager API 限流风险。
* **成本影响**: 每个密钥每月约 $0.40。

---

## 9. 验证凭证 (Validation Evidence)
* External Secrets Operator IAM IRSA 身份认证测试与密钥同步校验。

## 10. 验收条件 (Acceptance Conditions)
* 云安全 Lead 与 DevOps 负责人签署。

## 11. 重新评估触发条件 (Revisit Triggers)
* 出现多云迁移强制需求，要求使用云厂商无关的密钥存储。

## 12. 实施影响 (Implementation Implications)
* ESO Helm Chart 和 ExternalSecret CRD Manifests 将在阶段 3 部署。
