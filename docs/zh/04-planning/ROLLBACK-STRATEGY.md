# 变更回滚策略与标准流程说明书 (Rollback Strategy: DataBlue Platform)

---

## 1. 治理与回滚原则 (Governance & Rollback Principles)

本文档指定了 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 跨 9 个技术层级的强制性 **回滚策略与标准流程 (Rollback Strategies & Procedures)**。

根据 [`AGENTS.md`](../../AGENTS.md) 与 [`PROJECT-CHARTER.md`](../00-governance/PROJECT-CHARTER.md)：
* **每一项生产环境变更必须具备自动化的或书面记录的回滚流程。**
* **在未经备份与回滚验证的情况下，严禁计划任何破坏性变更操作。**

---

## 2. 逐层级回滚规范说明 (Layer-by-Layer Rollback Specifications)

### 1. 基础设施变更回滚 (Terraform / AWS 基础)
* **触发条件**: `terraform apply` 失败，或执行期间出现意外的资源销毁警告 (`WP-002`, `WP-004`)。
* **回滚流程**: 撤销 Terraform 仓库中的 Git Commit 提交；指向前一个 S3 State 状态文件版本执行 `terraform apply`；若需要则通过 AWS Backup 快照恢复已删除资源。
* **最大恢复时间**: < 30 分钟。

### 2. EKS 控制平面升级回滚
* **触发条件**: 升级后 EKS 控制平面 API Server 性能退化或插件不兼容 (`ADR-003`)。
* **回滚流程**: AWS EKS 控制平面托管升级**无法降级至上一个次要版本 (Minor Version)**。缓解措施需要在 Terraform 中并行拉起上一个次要版本的第二个 EKS 集群，通过 Velero 恢复集群状态，并切流 DNS Ingress。
* **最大恢复时间**: < 2 小时。

### 3. 节点升级与自动扩缩容回滚 (Karpenter)
* **触发条件**: 新的 EC2 AMI 节点池导致 Pod CrashLoopBackOff 崩溃或网络 CNI 故障 (`ADR-005`)。
* **回滚流程**: 在 Git 中更新 Karpenter `EC2NodeClass` CRD 指向上一个 AMI ID；执行 `karpenter.sh/do-not-disrupt: false`；Karpenter 封锁 (Cordon) 并驱逐 (Drain) 故障节点，替换为稳定的 AMI 实例。
* **最大恢复时间**: < 15 分钟。

### 4. 应用发布回滚 (微服务)
* **触发条件**: 部署后 HTTP 5xx 错误率 > 0.01% 或微服务 Pod 崩溃 (`WP-017`)。
* **回滚流程**: 自动化的 ArgoCD / Ansible 回滚。ArgoCD 将 Manifest 镜像标签还原至上一个稳定的 Git Commit SHA (`ecr.aws/microservice:previous-sha`)；滚动更新恢复健康 Pod ([`CICD-DELIVERY-PLAN.md`](CICD-DELIVERY-PLAN.md))。
* **最大恢复时间**: < 5 分钟。

### 5. 数据库 Schema 迁移回滚 (MySQL / MongoDB)
* **触发条件**: 迁移后 Schema 变更脚本失败或应用数据损坏 (`WP-011`)。
* **回滚流程**: 执行向下的 Liquibase / Flyway 回滚 SQL 脚本。若数据损坏，发起 Amazon RDS 时间点恢复 (PITR)，将数据库恢复至迁移脚本执行前精确的某一秒 (`ADR-013`)。
* **最大恢复时间**: < 30 分钟 (PITR 恢复)。

### 6. 中间件升级回滚 (Redis / RabbitMQ / Nacos)
* **触发条件**: 升级后有状态 Broker 分区故障或 Nacos Raft Quorum 稳定性失控 (`WP-012`, `WP-013`)。
* **回滚流程**: 通过 ArgoCD 还原 Helm Release 镜像标签；若 Schema 版本发生变动，则从 Velero S3 快照恢复卷状态。
* **最大恢复时间**: < 20 分钟。

### 7. IAM 与安全策略回滚
* **触发条件**: 过度严格的 IAM IRSA 策略更新阻断了 Pod 对 AWS API 的调用 (`WP-003`)。
* **回滚流程**: 撤销 Terraform 中的 IAM Policy HCL 模块；执行 `terraform apply`；EKS IRSA OIDC Pod Token 自动刷新恢复。
* **最大恢复时间**: < 10 分钟。

### 8. 网络架构与安全组回滚
* **触发条件**: NetworkPolicy 或 Security Group 误配置导致跨 AZ 微服务流量丢包 (`WP-004`)。
* **回滚流程**: 撤销 GitOps 仓库中的 Security Group HCL 模块或 NetworkPolicy YAML Manifest；ArgoCD 同步原始默认拒绝的入站/出站规则。
* **最大恢复时间**: < 5 分钟。

### 9. CI/CD 流水线与 Runner 回滚
* **触发条件**: Jenkins 工作节点或 Ansible Playbook 部署脚本出现错误 (`WP-010`)。
* **回滚流程**: 撤销共享服务仓库中的 Jenkinsfile / Ansible Playbook 提交；将流水线 Runner 锁定回上一个容器镜像版本。
* **最大恢复时间**: < 10 分钟。
