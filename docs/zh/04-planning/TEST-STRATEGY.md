# 测试策略与验证规划说明书 (Test Strategy & Validation Plan: DataBlue Platform)

---

## 1. 治理与测试哲学 (Governance & Testing Philosophy)

本文档制定了验证 **DataBlue 下一代基础设施平台** (`datablue-nextgen-infra-platform`) 的全面 **测试策略 (Test Strategy)**。

根据治理规则：
* **基础设施创建成功并不等于平台可用。**
* **部署成功并不等于就绪可运维。**
* 平台就绪需要在 11 个验证领域提供具体的实测凭证。

---

## 2. 11 个测试与验证领域 (11 Testing & Validation Domains)

### 1. 基础设施验证 (Infrastructure Validation)
* **范围**: 验证 VPC 子网、NAT 路由、AWS KMS 加密密钥及 IAM IRSA Role 绑定。
* **测试方法**: 自动化的 Terraform 模块验证 (`terraform plan`, `tflint`, `checkov` 安全扫描)。
* **成功标准**: 零安全 Lint 错误；100% 加密的 EBS/RDS 存储 (`SEC-003`)。

### 2. Kubernetes 平台引擎验证 (Kubernetes Platform Engine Validation)
* **范围**: EKS 控制平面 API Server 延迟、CoreDNS 解析、VPC CNI Pod IP 分配。
* **测试方法**: Sonobuoy Kubernetes 结果一致性测试套件。
* **成功标准**: 100% 通过 Upstream Kubernetes API 一致性测试。

### 3. 安全与访问控制测试 (Security & Access Control Testing)
* **范围**: Pod 与 Pod 间的 NetworkPolicies、IAM IRSA 最小权限范围、Secrets Manager 集成。
* **测试方法**: 模拟跨 Namespace Pod 流量注入（尝试非法入站访问）；通过 ESO 进行密钥同步验证 (`ADR-011`)。
* **成功标准**: 默认拒绝的 NetworkPolicies 阻断未经授权的 Pod 通信；零明文密钥暴露 (`SEC-001`)。

### 4. 性能与基准剖析测试 (Performance & Baseline Profiling)
* **范围**: 微服务延迟 (P95/P99)、数据库查询响应时间。
* **测试方法**: Locust / k6 模拟 API 端点基准测试。
* **成功标准**: 基准流量下 ALB 边界处 P95 延迟 < 200ms。

### 5. 负载与突发容量测试 (Load & Burst Capacity Testing)
* **范围**: 200% 峰值突发流量下的微服务性能表现。
* **测试方法**: 分布式 k6 负载生成器，模拟 10,000 个并发用户请求。
* **成功标准**: 零 HTTP 500 错误；动态 HPA 扩缩容成功触发 (`NFR-002`)。

### 6. 动态扩缩容测试 (Pod 与节点扩缩容)
* **范围**: 通过 HPA/KEDA 实现 Pod 扩缩容，通过 Karpenter JIT 自动扩缩容引擎实现节点扩缩容 (`ADR-005`)。
* **测试方法**: 注入不可调度的 Pod 需求；测量节点拉起时间。
* **成功标准**: Karpenter 在 < 60 秒内拉起 EC2 工作节点 (`NFR-002`)。

### 7. 高可用性与多可用区故障转移测试 (HA & Multi-AZ Failover Testing)
* **范围**: 模拟 EC2 工作节点崩溃及可用区网络停机。
* **测试方法**: Chaos Mesh 节点终止；AWS 故障注入模拟器 (FIS) AZ 黑洞。
* **成功标准**: Pod 重新调度至存活可用区；MySQL 数据库故障转移在 < 60 秒内完成且零数据丢失 (`NFR-001`)。

### 8. 备份与 PITR 恢复测试 (Backup & PITR Restoration Testing)
* **范围**: 时间点恢复 (PITR) 数据库恢复及 Velero Kubernetes 状态恢复。
* **测试方法**: 每月自动删表并恢复至隔离的测试子网 (`ADR-013`)。
* **成功标准**: 100% 数据库记录恢复至删表前精确的时间戳 (`RSK-DAT-002`)。

### 9. 灾难恢复 (DR) 跨区域故障转移演练 (DR Regional Failover Drills)
* **范围**: 模拟主 AWS 区域完全故障。
* **测试方法**: Cloudflare GTM / DNS 故障转移切换至备用区域 Pilot Light / 待命集群 (`ADR-014`)。
* **成功标准**: 满足 RTO 与 RPO 目标；备用区域平台恢复运营。

### 10. CI/CD 流水线与自动化回滚测试 (CI/CD Pipeline & Automated Rollback Testing)
* **范围**: GitLab $\rightarrow$ Jenkins $\rightarrow$ Ansible $\rightarrow$ ArgoCD 部署自动化与健康检查回滚。
* **测试方法**: 部署一个故障应用容器镜像；验证自动回滚 (`ADR-004`)。
* **成功标准**: ArgoCD 在 10 分钟内自动将镜像标签还原至上一个稳定 Commit。

### 11. FinOps 成本与标签验证 (FinOps Cost & Tagging Validation)
* **范围**: 验证 AWS 资源标签合规性及 Cost Explorer 分摊精准度。
* **测试方法**: 自动化的 AWS Config 规则扫描未打标签的资源 (`CST-002`)。
* **成功标准**: 100% 的 AWS 资源包含有效的 `CostCenter` 与 `Environment` 标签。
