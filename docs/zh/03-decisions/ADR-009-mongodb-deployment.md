# ADR-009 — MongoDB 文档数据库部署架构策略 (MongoDB Deployment Strategy)

## 元数据 (Metadata)
* **状态**: `暂缓/待定 (Deferred)`
* **日期**: 2026-08-03
* **决策负责人**: 数据架构主工程师 (Lead Data Architect), 云安全 Lead (Cloud Security Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), 应用开发 Lead (Application Development Lead)
* **关联需求**: [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-DAT-001` (Amazon DocumentDB 传输协议不兼容风险), `RSK-OPS-001` (自建 NoSQL 运维复杂度)
* **关联假设**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 3 节, 第 6 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `FUN-007` 规定需要 MongoDB 文档数据库服务，用于非结构化数据的持久化存储。我们必须评估部署策略：EKS 自建 MongoDB Operator、AWS 上的 MongoDB Atlas 托管服务、Amazon DocumentDB 或专有 EC2 MongoDB 集群。**关键在于：Amazon DocumentDB 并非 100% 兼容 MongoDB 传输协议 (Wire-Protocol)**，缺少对特定聚合管道算子、Change Stream 算子和索引类型的支持。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **传输协议兼容性**: 100% 兼容应用层的 MongoDB 驱动查询与聚合管道算子 (`FUN-007`)。
2. **副本集高可用性**: 跨可用区 (Multi-AZ) 主/从副本集自动故障转移 (`NFR-001`)。
3. **运维开销**: 自动化备份、存储自动扩展及副本集恢复 (`NFR-003`)。
4. **许可与 TCO**: SSPL 许可合规性 vs. AWS DocumentDB 成本开销 (`CST-001`)。

---

## 3. 约束条件 (Constraints)
* 必须支持微服务的文档存储，且无需重构微服务应用代码。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: EKS 自建 MongoDB Community / Enterprise Operator
* **描述**: 使用官方 MongoDB Kubernetes Operator 在 EKS 内部部署原生 MongoDB 副本集，后端由跨 3 可用区的 EBS `gp3` 存储提供支持。
* **优势**: 100% 纯正的 MongoDB 传输协议兼容性；零专有云数据库绑定；对 SSPL 许可和功能集拥有完全控制权。
* **劣势**: 团队必须自行管理副本集节点选举、EBS 存储扩展、备份自动化及节点维护。
* **安全性影响**: 良好。TLS 加密、SCRAM 身份验证、KMS 卷加密。
* **可用性影响**: 跨 3 可用区部署 3 成员副本集时表现强劲。
* **相关风险**: `RSK-OPS-001` (节点维护期间副本集主节点选举意外失败的风险)。

### 方案 2: AWS 上的 MongoDB Atlas (托管 SaaS)
* **描述**: 直接由 MongoDB 原生托管在 AWS 基础设施上的 MongoDB Atlas 数据库集群。
* **优势**: 100% 纯正的 MongoDB 兼容性；完全托管的多可用区扩展、自动化备份与安全补丁。
* **劣势**: 需要第三方 SaaS 供应商协议；潜在的 VPC Peering / AWS PrivateLink 配置复杂度。
* **安全性影响**: 极佳。AWS PrivateLink 隔离、KMS 加密、细粒度审计日志。
* **可用性影响**: 极佳 (99.99% SLA)。

### 方案 3: Amazon DocumentDB (MongoDB 兼容版)
* **描述**: AWS 专有的文档数据库服务，旨在兼容模拟 MongoDB 3.6/4.0/5.0 API。
* **优势**: 由 AWS 完全托管；集成了 AWS IAM、CloudWatch 和 KMS；分布式多可用区存储。
* **劣势**: **不完整的 MONGODB 传输协议兼容性**。缺少对特定聚合阶段（如 `$lookup` 限制）、Change Stream 功能及特定索引类型的支持。
* **安全性影响**: 极佳。原生 AWS IAM、KMS 和 CloudWatch 集成。
* **可用性影响**: 极佳 (99.99% SLA)。
* **前置条件**: **强制要求对所有微服务数据库查询针对 DocumentDB 功能支持矩阵进行代码审计**。
* **相关风险**: `RSK-DAT-001` (由于不支持的 MongoDB 语法导致应用驱动运行时崩溃)。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: EKS 自建 MongoDB | 方案 2: MongoDB Atlas | 方案 3: Amazon DocumentDB |
| :--- | :--- | :--- | :--- |
| **MongoDB 协议兼容性** | **100% (原生兼容)** | **100% (原生兼容)** | **未验证 (< 100%)** |
| **运维人力** | 沉重 | **极低** | **极低** |
| **厂商独立性** | **极高** | 中等 | 低 (AWS 绑定) |
| **成本效益 (`CST-001`)** | **高** | 中等 | 低 (高 AWS 管理费) |
| **可逆性** | **易于撤销** | 可逆 | 困难 |

---

## 6. 提议决策 (Proposed Decision)
**暂缓/待定决策 (Decision Deferred)**。

---

## 7. 决策依据 (Rationale)
在对应用的 MongoDB 查询**针对 Amazon DocumentDB 功能矩阵进行实测兼容性审计** (`RSK-DAT-001`) 完成之前，**暂缓做出最终决策**。

在缺少凭证的情况下声称 Amazon DocumentDB 可以无缝替代 MongoDB 是违反治理规则的。如果微服务需要不支持的 MongoDB 功能，将选择方案 1 (EKS 自建 Operator) 或方案 2 (MongoDB Atlas)。

---

## 8. 签署前所需的验证凭证
1. 针对 DocumentDB API 支持限制的微服务源码自动化查询/驱动兼容性扫描 (`RSK-DAT-001`)。
2. 微服务文档存储容量与 IOPS 剖析 (`OPEN-001`)。

## 9. 验收条件 (Acceptance Conditions)
* 完成 DocumentDB 兼容性审计并获得数据架构主工程师签署。

## 10. 重新评估触发条件 (Revisit Triggers)
* 在阶段 1 代码审查期间发现不兼容的 MongoDB 聚合管道。

## 11. 实施影响 (Implementation Implications)
* 平台架构分配隔离的数据库子网，能够支持 EKS Pods 或 PrivateLink 端点。
