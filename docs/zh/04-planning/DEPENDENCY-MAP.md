# 依赖关系映射图 (Dependency Map: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指明了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的技术、组织、凭证及治理依赖项。

依赖关系分为五大类：
1. **硬技术依赖 (Hard Dependencies)**: 物理上阻断后续执行的技术前置条件。
2. **软依赖 (Soft Dependencies)**: 提高效率但不会严格阻止执行的最佳实践顺序。
3. **外部依赖 (External Dependencies)**: 客户输入、第三方供应商 API 或组织批准。
4. **人工批准依赖 (Human Approval Dependencies)**: 需要正式人工签署的治理门槛 ([`ACCEPTANCE-GATES.md`](ACCEPTANCE-GATES.md))。
5. **凭证依赖 (Evidence Dependencies)**: 解锁决策所需的实测基准、剖析数据或审计。

---

## 2. 主依赖关系图 (Master Dependency Graph)

```mermaid
graph TD
    P0["阶段 0: 凭证收集"] --> G01["门槛 01: 需求基线"]
    G01 --> G03["门槛 03: ADR 批准"]
    G03 --> P1["阶段 1: AWS 基础建设"]
    
    P1 --> G04["门槛 04: AWS 基础就绪"]
    G04 --> P2["阶段 2: 测试平台建设"]
    
    P2 --> G05["门槛 05: 测试平台就绪"]
    G05 --> P3["阶段 3: 共享服务安装"]
    G05 --> P4["阶段 4: CI/CD 集成"]
    
    P3 --> P5["阶段 5: 有状态中间件交付"]
    P4 --> P5
    
    P5 --> P6["阶段 6: 技术试点上线"]
    P6 --> G06["门槛 06: 技术试点验收通过"]
    
    G06 --> G07["门槛 07: 生产建设批准 CAB"]
    G07 --> P7["阶段 7: 生产平台建设"]
    
    P7 --> P8["阶段 8: 迁移波次 1-5"]
    P8 --> G09["门槛 09: 迁移波次签署"]
    
    G09 --> P9["阶段 9: 生产就绪与混沌 DR"]
    P9 --> G08["门槛 08: 生产就绪验收通过"]
    
    G08 --> P10["阶段 10: 运维交接"]
    P10 --> G10["门槛 10: 交接验收通过"]

    classDef gate fill:#f9f,stroke:#333,stroke-width:2px;
    classDef hard fill:#bbf,stroke:#333,stroke-width:1px;
    classDef evid fill:#ffd,stroke:#333,stroke-width:1px;

    class G01,G03,G04,G05,G06,G07,G08,G09,G10 gate;
    class P1,P2,P3,P4,P5,P6,P7,P8,P9,P10 hard;
    class P0 evid;
```

---

## 3. 详细依赖关系矩阵 (Detailed Dependency Matrix)

### 1. 凭证依赖 (Evidence Dependencies)
* `DEP-EVD-001`: **微服务容量剖析数据** (`OPEN-001`) $\rightarrow$ 用于解锁 [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) (MySQL), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) (Redis), [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md) (RabbitMQ), 及 `WP-011`–`WP-012`。
* `DEP-EVD-002`: **DocumentDB 与 MongoDB 协议兼容性审计** (`RSK-DAT-001`) $\rightarrow$ 用于解锁 [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md) (MongoDB)。
* `DEP-EVD-003`: **业务连续性 RTO/RPO 签署** (`OPEN-003`) $\rightarrow$ 用于解锁 [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) (灾难恢复)。

### 2. 人工批准依赖 (Human Approval Dependencies)
* `DEP-HUM-001`: [`GATE-03`](ACCEPTANCE-GATES.md) **ADR 签署** $\rightarrow$ 在阶段 1 基础执行 (`WP-002`) 前需要对提议 ADRs (`ADR-001`..`015`) 进行人工审查。
* `DEP-HUM-002`: [`GATE-07`](ACCEPTANCE-GATES.md) **CAB 生产批准** $\rightarrow$ 在创建 `DataBlue-Prod-Account` (`WP-015`) 前需要变更咨询委员会授权。
* `DEP-HUM-003`: [`GATE-10`](ACCEPTANCE-GATES.md) **交接验收通过** $\rightarrow$ 项目结项完成 (`WP-020`) 需要运维 Lead 签署。

### 3. 硬技术依赖 (Hard Technical Dependencies)
* `DEP-TRC-001`: **多账号 Landing Zone (`WP-002`)** $\rightarrow$ VPC 网络 (`WP-004`) 与测试 EKS 集群 (`WP-005`) 的物理前置条件。
* `DEP-TRC-002`: **测试 EKS 集群 (`WP-005`)** $\rightarrow$ 共享平台服务 (`WP-007`..`WP-009`) 与 CI/CD 流水线 (`WP-010`) 的物理前置条件。
* `DEP-TRC-003`: **MySQL 数据库层 (`WP-011`)** $\rightarrow$ Nacos 集群部署 (`WP-013`) 的物理前置条件。
* `DEP-TRC-004`: **测试环境验证 (`WP-014`)** $\rightarrow$ 生产集群建设 (`WP-015`) 的物理前置条件。

### 4. 外部依赖 (External Dependencies)
* `DEP-EXT-001`: **AWS 账号配额与域名注册** $\rightarrow$ 客户 AWS Organizations 根账号权限及 Cloudflare 公网域名 & DNS 访问权限。
* `DEP-EXT-002`: **GitLab & Jenkins 现有仓库** $\rightarrow$ 客户开发者对源码仓库的访问权限。
