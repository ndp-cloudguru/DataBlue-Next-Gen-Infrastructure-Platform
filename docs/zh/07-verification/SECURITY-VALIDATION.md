# 安全审计与验证规划说明书 (Security Validation: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **安全验证规范与审计计划 (Security Validation Specification & Audit Plan)**。

根据需求 [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md)、[`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md) 及 [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)：
* 在进入生产环境 ([`GATE-07`](../04-planning/ACCEPTANCE-GATES.md)) 之前，安全控制跨 6 个安全层级进行审计。
* **严禁预先将测试结果标记为通过**。所有的安全验证检查项目前均处于 `待定 (Pending)` 状态。

---

## 2. 6 层安全验证矩阵 (6-Layer Security Validation Matrix)

| 安全层级 | 治理需求 / ADR | 验证审计范围 | 目标通过验收标准 | 强制性凭证 ID | 负责角色 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 身份与 IAM 范围** | [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md) | AWS IAM IRSA Pod 角色范围及 IAM Access Analyzer 扫描 | Pod 角色中零通配符 (`*`) IAM 权限 | `EVD-SEC-002` | 云安全 Lead | `待定 (Pending)` |
| **2. 容器漏洞扫描** | [`FUN-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | 容器镜像上的 Jenkins Trivy CVE 扫描 | 容器镜像中零 `CRITICAL` 严重漏洞 | `EVD-SEC-001` | DevOps Lead | `待定 (Pending)` |
| **3. 网络边界隔离**| [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md) | VPC 子网、安全组及 NetworkPolicies | 通往隔离 DB 子网的零直接公网路由 | `EVD-ENV-001` | 网络架构师 | `待定 (Pending)` |
| **4. 密钥管理** | [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md) | AWS Secrets Manager + External Secrets Operator (ESO) | 零提交至 Git 的静态明文密钥 | `EVD-SEC-005` | 安全工程师 | `待定 (Pending)` |
| **5. 静态数据加密** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md) | AWS KMS 客户托管密钥 (CMK) 配置 | 100% 加密的 EBS 卷、RDS DBs 及 S3 | `EVD-SEC-004` | 云安全 Lead | `待定 (Pending)` |
| **6. 传输中数据加密** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md) | Ingress ALB 上的 TLS 1.3 加密及 mTLS Pod 路由 | 公网端点获得 SSL Labs A 级评级 | `EVD-ING-001` | DevOps 工程师 | `待定 (Pending)` |

---

## 3. 安全验证测试协议 (Security Validation Test Procedures)

### 测试 SEC-01 — 最小权限 IAM IRSA 审计
* **步骤**: 针对附加至 EKS 服务账号的所有 IRSA 角色 ARN 执行自动化的 IAM Access Analyzer 检查。
* **通过标准**: 包含 `Action: "*"` 或 `Resource: "*"` 的策略数为 `0`。

### 测试 SEC-02 — 隔离数据库子网入站审计
* **步骤**: 从测试 Pod 针对非授权端口上的数据库子网执行模拟网络探测。
* **通过标准**: 100% 的未经授权连接尝试被 AWS 安全组丢弃。

### 测试 SEC-03 — 容器镜像漏洞扫描
* **步骤**: 在 Jenkins 容器构建流水线期间运行 Trivy 漏洞扫描 (`FUN-003`)。
* **通过标准**: 当且仅当发现零 `CRITICAL` 严重 CVE 时，Jenkins 构建成功。
