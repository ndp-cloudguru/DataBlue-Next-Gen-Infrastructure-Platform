# 性能与扩缩容验证规划说明书 (Performance Validation: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的 **性能与扩缩容验证规范 (Performance & Scaling Validation Specification)**。

根据需求 [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) 及 [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md)：
* 压力测试与节点自动扩缩容基准测试针对技术试点应用系统执行 (`WP-014`)。
* **严禁预先将测试结果标记为通过**。所有的性能验证检查项目前均处于 `待定 (Pending)` 状态。

---

## 2. 性能与扩缩容验证矩阵 (Performance & Scaling Validation Matrix)

| 性能分类 | 治理需求 / ADR | 验证审计范围 | 目标通过验收标准 | 强制性凭证 ID | 负责角色 | 验证状态 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Ingress 延迟 (P95)** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md) | 基准负载下 ALB Ingress API 响应时间 | ALB 入口边界处 P95 延迟 < 200ms | `EVD-PRF-001` | 性能 Lead | `待定 (Pending)` |
| **2. Ingress 延迟 (P99)** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md) | 基准负载下 ALB Ingress API 响应时间 | ALB 入口边界处 P99 延迟 < 500ms | `EVD-PRF-001` | 性能 Lead | `待定 (Pending)` |
| **3. 突发负载能力** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | 分布式 k6 突发负载 (200% 峰值吞吐量) | 在 200% 突发负载下零 HTTP 500 错误 | `EVD-PRF-001` | 性能 Lead | `待定 (Pending)` |
| **4. Pod 自动扩缩容 (HPA)** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | 触发 70% CPU 阈值时的 HPA Pod 副本扩容 | Pod 副本在 < 30 秒内完成扩容 | `EVD-SCL-001` | SRE Lead | `待定 (Pending)` |
| **5. 节点自动扩缩容** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | Karpenter JIT EC2 节点拉起 | 新节点在 < 60s 内完成拉起并就绪 | `EVD-SCL-001` | SRE Lead | `待定 (Pending)` |
| **6. 数据库读取延迟** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | MySQL Read-Replica 只读端点查询性能 | P95 DB 查询延迟 < 10ms | `EVD-DB-003` | DBA Lead | `待定 (Pending)` |
| **7. Redis 缓存延迟** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | ElastiCache Redis 集群读写响应 | Redis 指令响应延迟 < 2ms | `EVD-CACHE-001` | 基础设施 Lead | `待定 (Pending)` |

---

## 3. 扩缩容基准测试执行协议 (Scaling Benchmark Test Protocols)

### 测试 PRF-01 — Karpenter 节点拉起延迟基准测试
* **步骤**: 同时向 EKS 测试集群注入 50 个无法调度的 Pod 资源请求。
* **指标**: `PodScheduled: False` 状态与 `NodeReady: True` 状态之间流逝的时间。
* **通过标准**: Karpenter 拉起请求的 EC2 实例节点并在 < 60 秒内达到 `Ready` 状态 (`EVD-SCL-001`)。

### 测试 PRF-02 — 10,000 并发用户压力测试
* **步骤**: 执行 15 分钟分布式 k6 压力测试，模拟 10,000 个并发虚拟用户请求微服务 API 端点。
* **通过标准**: 错误率 < 0.01%，ALB P95 延迟 < 200ms (`EVD-PRF-001`)。
