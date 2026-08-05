# ADR-007 — Redis 缓存集群部署架构策略 (Redis Deployment Strategy)

## 元数据 (Metadata)
* **状态**: `暂缓/待定 (Deferred)`
* **日期**: 2026-08-03
* **决策负责人**: 数据架构主工程师 (Lead Data Architect), 云基础设施 Lead (Cloud Infrastructure Lead)
* **审查团队**: 企业架构委员会 (Enterprise Architecture Board), FinOps 团队 (FinOps Team)
* **关联需求**: [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **关联风险**: `RSK-UNC-001` (缺少缓存内存指标), `RSK-OPS-001` (自建缓存运维维护开销)
* **关联假设**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **关联架构文档**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) 第 3 节, 第 6 节
* **替代决策**: 无
* **被替代决策**: 无

---

## 1. 上下文与问题陈述 (Context & Problem Statement)
需求 `FUN-008` 规定需要内存级 Redis 缓存，用于微服务间的瞬态 Session 存储与高速数据缓存。我们必须评估是在 EKS 内部部署 Redis 还是利用 Amazon ElastiCache for Redis 托管服务。目前尚未确认缓存内存容量、驱逐率及命中/未命中比例 (`OPEN-001`)。

---

## 2. 决策驱动因素 (Decision Drivers)
1. **亚毫秒级延迟**: 保障低延迟的缓存读写 (`FUN-008`)。
2. **高可用性与缓存持久性**: 多可用区故障转移及数据复制，节点重启时缓存数据不丢失 (`NFR-001`)。
3. **运维简易度**: 消除了手动 Redis 集群分片与 Slot 迁移维护开销。
4. **成本优化**: 在 AWS 托管缓存小时节点费与工作节点 RAM 消费之间取得平衡 (`CST-001`)。

---

## 3. 约束条件 (Constraints)
* 必须支持标准 Redis 7.0+ API 协议。

---

## 4. 备选方案评估 (Options Considered)

### 方案 1: EKS 自建 Redis 集群 (Bitnami Helm / Redis Operator)
* **描述**: 在 EKS 内部托管 Redis Sentinel 或 Redis Cluster Pods，使用 Kubernetes 工作节点的 RAM 内存，并由临时盘或 EBS 存储备份。
* **优势**: 零 ElastiCache 托管服务溢价；对 Redis 配置参数拥有完全控制权；完全的云可移植性。
* **劣势**: 消耗昂贵的工作节点 RAM 内存；Pod 重新调度将引发缓存冷启动或重新分片开销；需要手动管理集群 Slot 槽位。
* **安全性影响**: 中等。手动配置 TLS 加密和网络策略。
* **可用性影响**: 中等。Pod 故障在故障转移完成前会导致瞬时缓存未命中。
* **相关风险**: `RSK-OPS-001` (缓存 Pod 驱逐导致级联数据库超载的风险)。

### 方案 2: Amazon ElastiCache for Redis (Multi-AZ 复制组) — 推荐基线
* **描述**: 完全托管的专有 Amazon ElastiCache Redis 集群，跨多个可用区部署，支持自动故障转移。
* **优势**: 亚毫秒级延迟；自动 Multi-AZ 故障转移 (< 30 秒)；剥离 EKS 工作节点的内存负担；托管的安全补丁更新。
* **劣势**: 专有的小时节点定价 (`cache.m6g` 实例)；潜在的跨可用区数据传输费。
* **安全性影响**: 极佳。静态 KMS 加密、传输 TLS 加密、IAM 身份验证。
* **可用性影响**: 强 (99.99% SLA)。
* **运维影响**: 对 DevOps 团队产生的运维负担极小。

---

## 5. 方案对比矩阵 (Comparative Evaluation)

| 评估标准 | 方案 1: EKS 自建 Redis | 方案 2: Amazon ElastiCache for Redis |
| :--- | :--- | :--- |
| **延迟 & SLA** | 中等-高 | **亚毫秒级 (99.99%)** |
| **运维人力** | 高 | **极低** |
| **工作节点 RAM 竞争** | 高风险 | **零内存竞争** |
| **成本可预测性** | 高 | 中等 |
| **可逆性** | **易于撤销** | 可逆 |

---

## 6. 提议决策 (Proposed Decision)
**暂缓/待定决策 (Decision Deferred)**。

---

## 7. 决策依据 (Rationale)
在完成微服务缓存内存剖析 (`OPEN-001`) 之前，**暂缓对 Amazon ElastiCache for Redis 与 EKS 自建 Redis 做出最终选择**。

如果总缓存内存需求较小 (< 4 GB)，在 EKS 上自建具备成本效益；如果缓存需求超过 16 GB 且具有高并发，则必须采用 ElastiCache 以保障工作节点的稳定性。

---

## 8. 签署前所需的验证凭证
1. 微服务缓存内存占用、TTL 驱逐策略及查询 RPS 指标 (`OPEN-001`)。
2. FinOps 成本门槛批准。

## 9. 验收条件 (Acceptance Conditions)
* 提交验证通过的缓存内存基准测试并完成架构委员会审查。

## 10. 重新评估触发条件 (Revisit Triggers)
* 阶段 1 工作负载剖析完成。

## 11. 实施影响 (Implementation Implications)
* 网络设计分配专有的 DB 子网，具备托管上述任一方案的能力。
