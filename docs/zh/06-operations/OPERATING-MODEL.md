# 平台运维模型说明书 (Operating Model: DataBlue Platform)

---

## 1. 概述 (Overview)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的运维治理规范、RACI 职责分配矩阵及技术域边界。

---

## 2. RACI 运维职责分配矩阵 (RACI Operational Responsibility Matrix)

* **R**: Responsible (负责执行 - 具体执行工作)
* **A**: Accountable (最终负责 - 最终决策与责任人)
* **C**: Consulted (咨询 - 提供专业输入)
* **I**: Informed (知会 - 保持信息同步)

| 运维领域与技术范围 | 云平台 SRE & DevSecOps 团队 | 数据库管理团队 (DBA) | 应用开发团队 (App Dev) | 企业运维与支持团队 (Ops) |
| :--- | :--- | :--- | :--- | :--- |
| **AWS 账号 Landing Zone & VPC 子网**| **A / R** | 知会 | 知会 | 知会 |
| **EKS 控制平面与工作节点** | **A / R** | 知会 | 知会 | 知会 |
| **IAM IRSA, KMS 密钥与安全审计** | **A / R** | 知会 | 知会 | 知会 |
| **CI/CD 流水线工具链与 ECR** | **A / R** | 知会 | 咨询 | 知会 |
| **ArgoCD GitOps 发布与 Manifests** | **A / R** | 知会 | 咨询 | 知会 |
| **数据库运维 (MySQL & DocumentDB)**| 咨询 | **A / R** | 咨询 | 知会 |
| **缓存与队列运维 (Redis & RabbitMQ)**| 咨询 | **A / R** | 咨询 | 知会 |
| **Nacos 服务发现中心运维** | **A / R** | 咨询 | 咨询 | 知会 |
| **微服务代码与 Pod 规格定义** | 咨询 | 知会 | **A / R** | 知会 |
| **Prometheus, Grafana & APM 指标** | **A / R** | 知会 | 咨询 | 咨询 |
| **集中式日志 (OpenSearch & S3)** | **A / R** | 知会 | 知会 | 知会 |
| **备份与 Velero 快照** | **A / R** | 咨询 | 知会 | 知会 |
| **灾难恢复 (DR) 故障转移** | **A / R** | 咨询 | 知会 | 咨询 |
| **24/7 故障响应与紧急升级**| **A / R** | 咨询 | 咨询 | **R** |
