# 有状态中间件交付规划说明书 (Middleware Delivery Plan: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 所需的 5 个有状态中间件服务的具体交付路径、高可用拓扑、备份方式及运维生命周期：
1. **MySQL** (`FUN-005`)
2. **Redis** (`FUN-008`)
3. **RabbitMQ** (`FUN-006`)
4. **MongoDB** (`FUN-007`)
5. **Nacos** (`FUN-009`)

未解决的阶段 3 ADRs (`ADR-006`..`009`) 均附带标明了解锁所需的凭证。

---

## 2. 中间件组件交付规范 (Middleware Component Delivery Specifications)

### 2.1 MySQL 关系型数据库 (`FUN-005`)
* **提议 / 候选部署模型**: Amazon RDS for MySQL (Multi-AZ) vs. EKS 自建 MySQL Operator (`ADR 候选: ADR-006`)。
* **未解决的 ADR 状态**: **`暂缓/待定 (Deferred)`** (`ADR-006`)。
* **解锁所需的凭证**: 来自阶段 0 的 DB 存储容量、交易 IOPS 及读写比例数据 (`OPEN-001`)。
* **环境拓扑**: 主实例位于 AZ-a，同步备用实例位于 AZ-b (数据库 VPC 子网)。
* **高可用模型**: 自动 Multi-AZ 故障转移 (< 60 秒)，配合 DNS CNAME 自动切流 (`NFR-001`)。
* **备份与恢复方式**: 每日自动快照 + 30 天时间点恢复 (PITR) 持续交易日志记录 (`ADR-013`)。每月自动恢复验证至隔离的测试子网 (`RSK-DAT-002`)。
* **监控与告警**: AWS CloudWatch + Prometheus mysqld_exporter 指标 (连接数 > 80%, CPU > 85%, 剩余存储 < 15%)。
* **扩容方式**: 垂直实例规格调整 (`db.m6g.xlarge`) + 只读副本端点分流 (`NFR-004`)。

---

### 2.2 Redis 内存级缓存 (`FUN-008`)
* **提议 / 候选部署模型**: Amazon ElastiCache for Redis vs. EKS 自建 Redis 集群 (`ADR 候选: ADR-007`)。
* **未解决的 ADR 状态**: **`暂缓/待定 (Deferred)`** (`ADR-007`)。
* **解锁所需的凭证**: 缓存内存 RAM 占用与驱逐策略剖析 (`OPEN-001`)。
* **环境拓扑**: 跨 AZ-a, AZ-b, AZ-c 部署的 2 节点 / 3 节点复制组 (数据库子网)。
* **高可用模型**: Multi-AZ 主/从故障转移 (< 30 秒)，配合自动端点路由。
* **备份方式**: 每日自动 RDB 快照导出至 S3 (`ADR-013`)。
* **监控与告警**: ElastiCache `EngineCPUUtilization`, `DatabaseMemoryUsagePercentage` 及 `CacheMissRate` 指标告警。
* **扩容方式**: 在线节点规格调整 (`cache.m6g.large`) 与集群分片扩容。

---

### 2.3 RabbitMQ 消息代理 (`FUN-006`)
* **提议 / 候选部署模型**: EKS 上的 RabbitMQ Cluster Kubernetes Operator vs. Amazon MQ for RabbitMQ (`ADR 候选: ADR-008`)。
* **未解决的 ADR 状态**: **`暂缓/待定 (Deferred)`** (`ADR-008`)。
* **解锁所需的凭证**: 消息吞吐量 (msg/sec)、队列深度及 Payload 大小指标 (`OPEN-001`)。
* **环境拓扑**: 跨 AZ-a, AZ-b, AZ-c 部署的 3 节点 Erlang 集群。
* **高可用模型**: 跨 3 个节点复制的 Quorum 队列 (`NFR-001`)。
* **备份方式**: Velero EKS 状态卷备份 + RabbitMQ Definitions JSON 导出 (`ADR-013`)。
* **监控与告警**: Prometheus `rabbitmq_queue_messages_ready` 及 `rabbitmq_erlang_mem_limit` 告警。
* **扩容方式**: 动态 Pod 副本扩容 + EBS `gp3` 存储自动扩容。

---

### 2.4 MongoDB 文档数据库 (`FUN-007`)
* **提议 / 候选部署模型**: EKS 自建 MongoDB Operator vs. MongoDB Atlas vs. Amazon DocumentDB (`ADR 候选: ADR-009`)。
* **未解决的 ADR 状态**: **`暂缓/待定 (Deferred)`** (`ADR-009`)。
* **解锁所需的凭证**: **强制要求针对 DocumentDB 传输协议兼容性对应用查询进行代码审计** (`RSK-DAT-001`)。
* **环境拓扑**: 跨 3 个可用区的 3 成员副本集 (1 主 2 从)。
* **高可用模型**: 主节点故障时自动副本集选举 (< 15 秒)。
* **备份方式**: 每日卷快照 + oplog 持续归档实现 30 天 PITR (`ADR-013`)。
* **监控与告警**: MongoDB exporter `opcounter`, `asserts` 及 `mem_resident` 告警。

---

### 2.5 Nacos 服务注册与动态配置中心 (`FUN-009`)
* **提议 / 候选部署模型**: EKS 上的 Nacos 集群 StatefulSet (`ADR-010`)。
* **未解决的 ADR 状态**: **`待审查 (Proposed)`** (`ADR-010`)。
* **环境拓扑**: 跨 AZ-a, AZ-b, AZ-c 私有应用子网部署的 3 节点 Nacos Raft 集群。
* **高可用模型**: 由 MySQL 关系型数据库层提供支持的 Nacos Raft 共识 Quorum。
* **备份方式**: Nacos 配置数据通过 MySQL 数据库快照进行备份 (`ADR-013`)。
* **监控与告警**: Nacos Actuator 健康指标 + MySQL 连接池跟踪。
* **扩容方式**: 水平 Pod 副本扩容 (`3` $\rightarrow$ `5` 节点)。
