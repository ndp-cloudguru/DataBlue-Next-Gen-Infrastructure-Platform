# Cấu trúc Phân chia Công việc (WBS): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Quản trị & Cấu trúc

Tài liệu này quy định **Cấu trúc Phân chia Công việc (WBS)** hoàn chỉnh để triển khai **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Mỗi gói công việc (Work Package - WP) đều có thể truy xuất nguồn gốc về các ID Yêu cầu (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`), Hồ sơ Quyết định Kiến trúc (`ADR`), và các ID Rủi ro (`RSK`).

---

## 2. Danh mục Gói Công việc (WP-001 đến WP-020)

### `WP-001`: Thu thập Bằng chứng Tải công việc & Khung Đo đạc Tải
* **Mô tả**: Thiết lập các công cụ đo đạc tải trong môi trường non-prod để thu thập các chỉ số CPU, RAM, IOPS và RPS cho ~40 microservices (`OPEN-001`).
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Rủi ro Liên quan**: `RSK-UNC-001`, `RSK-UNC-002`, `RSK-DAT-001`
* **Phụ thuộc**: Không (Giai đoạn 0)
* **Đầu vào**: Ảnh container legacy, mã nguồn lập trình viên.
* **Đầu ra**: Báo cáo Đo đạc Tải công việc được Xác minh & Các ADR Middleware được Giải quyết.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Trưởng Đám mây / Trưởng nhóm SRE
* **Xác minh**: Phân tích chỉ số tài nguyên Goldilocks / Prometheus.
* **Phương pháp Rollback**: Tháo bỏ các sidecar đo đạc tải tạm thời.
* **Tiêu chí Hoàn thành**: 100% chỉ số định kích thước microservice được ghi log và phê duyệt.
* **Trạng thái**: Sẵn sàng Thực thi

---

### `WP-002`: Cấp phát AWS Landing Zone & Cấu trúc Đa Tài khoản
* **Mô tả**: Cấp phát cấu trúc AWS Organization đa tài khoản (`DataBlue-Test`, `DataBlue-Prod`, `Shared-Services`, `Security-Account`).
* **Yêu cầu Liên quan**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-015`](../03-decisions/ADR-015-infrastructure-as-code.md)
* **Rủi ro Liên quan**: `RSK-SEC-003`, `RSK-CST-001`
* **Phụ thuộc**: `WP-001`, [`GATE-03`](ACCEPTANCE-GATES.md)
* **Đầu vào**: Thông tin đăng nhập root AWS Organization, bản thiết kế Control Tower.
* **Đầu ra**: Các Tài khoản AWS được cấp phát với remote S3 Terraform state backends.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Trưởng Hạ tầng
* **Xác minh**: Xác minh AWS Organizations API và kiểm toán truy cập tài khoản.
* **Phương pháp Rollback**: Hủy cấp phát đơn vị tổ chức (OU) mục tiêu qua Terraform.
* **Tiêu chí Hoàn thành**: Ký duyệt [`GATE-04`](ACCEPTANCE-GATES.md).
* **Trạng thái**: Chờ Phê duyệt `GATE-03`

---

### `WP-003`: Thiết lập IAM Identity Center, IRSA Roles & Baseline Bảo mật
* **Mô tả**: Cấu hình IAM Identity Center tập trung, OIDC provider cho EKS, và IAM Roles for Service Accounts (IRSA).
* **Yêu cầu Liên quan**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Rủi ro Liên quan**: `RSK-SEC-001`, `RSK-SEC-002`
* **Phụ thuộc**: `WP-002`
* **Đầu vào**: Quy cách chính sách IAM, các endpoint thư mục SSO doanh nghiệp.
* **Đầu ra**: Liên kết OIDC provider, các role IRSA, các key KMS do khách hàng quản lý (CMKs).
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm Bảo mật Đám mây
* **Xác minh**: Quét tự động bằng công cụ phân tích chính sách IAM đặc quyền tối thiểu.
* **Phương pháp Rollback**: Xóa các chính sách IAM role đã tạo qua Terraform.
* **Tiêu chí Hoàn thành**: 0 quyền IAM dạng wildcard (`*`).
* **Trạng thái**: Chờ `WP-002`

---

### `WP-004`: Thiết lập Kiến trúc Mạng VPC, Subnets & Định tuyến
* **Mô tả**: Triển khai topo mạng VPC 3 phân tầng trên 3 Availability Zones (Subnet Public, Application Private, Database Cô lập).
* **Yêu cầu Liên quan**: [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md)
* **Rủi ro Liên quan**: `RSK-SEC-003`, `RSK-CST-001`
* **Phụ thuộc**: `WP-002`
* **Đầu vào**: Sơ đồ phân bổ CIDR mạng.
* **Đầu ra**: VPCs, subnets, NAT Gateways, các bảng định tuyến, và security groups.
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm Hạ tầng Mạng
* **Xác minh**: Kiểm thử định tuyến và kiểm thử cô lập subnet tự động.
* **Phương pháp Rollback**: `terraform destroy` trên module VPC mục tiêu.
* **Tiêu chí Hoàn thành**: 0 tuyến đường giữa subnet database cô lập và internet công cộng.
* **Trạng thái**: Chờ `WP-002`

---

### `WP-005`: Xây dựng EKS Control Plane Test & Worker Node Groups
* **Mô tả**: Triển khai EKS cluster Test chuyên trách (`v1.30+`) trong `DataBlue-Test-Account` trên 3 AZs.
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md), [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md)
* **Rủi ro Liên quan**: `RSK-OPS-001`, `RSK-SCL-001`
* **Phụ thuộc**: `WP-003`, `WP-004`
* **Đầu vào**: Quy cách module Terraform EKS cluster.
* **Đầu ra**: EKS Test cluster đang hoạt động với AWS VPC CNI, CoreDNS, và kube-proxy.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Hạ tầng Đám mây
* **Xác minh**: `kubectl cluster-info` và kiểm tra sức khỏe trạng thái node.
* **Phương pháp Rollback**: `terraform destroy` trên module EKS Test.
* **Tiêu chí Hoàn thành**: Ký duyệt [`GATE-05`](ACCEPTANCE-GATES.md).
* **Trạng thái**: Chờ `WP-004`

---

### `WP-006`: Tích hợp Ingress Môi trường Test, DNS & SSL/TLS Certificate
* **Mô tả**: Cài đặt AWS Load Balancer Controller, cấu hình Cloudflare DNS & AWS Private Hosted Zones, và cấp phát ACM TLS certificates.
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Rủi ro Liên quan**: `RSK-SEC-001`
* **Phụ thuộc**: `WP-005`
* **Đầu vào**: Quy cách tên miền, yêu cầu chứng chỉ ACM.
* **Đầu ra**: Định tuyến ALB Ingress hoạt động tốt với mã hóa TLS 1.3 hợp lệ.
* **Vai trò Chịu trách nhiệm**: Kỹ sư DevOps
* **Xác minh**: Các yêu cầu curl HTTPS giả lập xác minh chuỗi SSL certificate.
* **Phương pháp Rollback**: Gỡ bỏ ALB Controller Helm chart.
* **Tiêu chí Hoàn thành**: Đạt xếp hạng SSL Labs hạng A cho các endpoint ingress.
* **Trạng thái**: Chờ `WP-005`

---

### `WP-007`: Nền tảng GitOps (ArgoCD) & Quản lý Release Helm
* **Mô tả**: Triển khai ArgoCD GitOps controller vào Test EKS cluster để quản lý khai báo manifest cluster.
* **Yêu cầu Liên quan**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md), [`ADR-015`](../03-decisions/ADR-015-infrastructure-as-code.md)
* **Rủi ro Liên quan**: `RSK-ARC-001`
* **Phụ thuộc**: `WP-005`
* **Đầu vào**: File values ArgoCD Helm, URIs repository ứng dụng GitOps.
* **Đầu ra**: Instance ArgoCD hoạt động đồng bộ manifest cluster từ Git.
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm DevOps
* **Xác minh**: Kiểm toán trạng thái đồng bộ ArgoCD trên các namespace nền tảng.
* **Phương pháp Rollback**: Xóa các custom resource của ArgoCD.
* **Tiêu chí Hoàn thành**: 100% add-on nền tảng được quản lý dưới sự kiểm soát của GitOps.
* **Trạng thái**: Chờ `WP-005`

---

### `WP-008`: Triển khai Observability Stack (Prometheus/Grafana + OpenSearch + S3)
* **Mô tả**: Triển khai Prometheus Operator, Grafana dashboards, bộ chuyển tiếp log Fluent Bit, Amazon OpenSearch cluster, và các quy tắc vòng đời S3 log.
* **Yêu cầu Liên quan**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **Rủi ro Liên quan**: `RSK-CST-002`, `RSK-OPS-002`
* **Phụ thuộc**: `WP-007`
* **Đầu vào**: Cấu hình thu thập Prometheus, template dashboard Grafana, quy cách domain OpenSearch.
* **Đầu ra**: Các dashboard giám sát vận hành và năng lực tìm kiếm log với lưu trữ S3 Glacier.
* **Vai trò Chịu trách nhiệm**: Kỹ sư Trưởng Vận hành
* **Xác minh**: Nạp log/metric giả lập xác minh hiển thị dashboard end-to-end.
* **Phương pháp Rollback**: Gỡ bỏ các Helm release Observability.
* **Tiêu chí Hoàn thành**: Tìm kiếm log tập trung hoạt động với xác minh xuất lưu trữ S3.
* **Trạng thái**: Chờ `WP-007`

---

### `WP-009`: Bảo mật Nền tảng & Quản lý Secrets (ESO + AWS Secrets Manager)
* **Mô tả**: Triển khai External Secrets Operator (ESO) liên kết với AWS Secrets Manager qua các IAM IRSA role.
* **Yêu cầu Liên quan**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Rủi ro Liên quan**: `RSK-SEC-001`, `RSK-SEC-002`
* **Phụ thuộc**: `WP-003`, `WP-007`
* **Đầu vào**: Quy cách secret AWS Secrets Manager, manifests ESO ClusterSecretStore.
* **Đầu ra**: Tự động đồng bộ secret từ AWS Secrets Manager vào K8s secrets.
* **Vai trò Chịu trách nhiệm**: Kỹ sư Bảo mật
* **Xác minh**: Kiểm thử tạo và đồng bộ secret bên trong namespace non-prod.
* **Phương pháp Rollback**: Xóa custom resource controller ESO.
* **Tiêu chí Hoàn thành**: 0 secret tĩnh plain-text bị commit vào Git.
* **Trạng thái**: Chờ `WP-007`

---

### `WP-010`: Tích hợp Bộ công cụ Pipeline CI/CD (GitLab + Jenkins + Ansible)
* **Mô tả**: Tích hợp Webhooks nguồn GitLab, dựng worker node Jenkins, và viết playbook tự động hóa triển khai Ansible.
* **Yêu cầu Liên quan**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Rủi ro Liên quan**: `RSK-ARC-001`, `RSK-SEC-001`
* **Phụ thuộc**: `WP-007`, `WP-009`
* **Đầu vào**: Templates Jenkinsfile, playbooks Ansible, URIs repository ECR.
* **Đầu ra**: Pipeline triển khai tự động hóa end-to-end có quét ảnh ECR.
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm DevOps
* **Xác minh**: Kiểm thử thực thi pipeline triển khai dry-run.
* **Phương pháp Rollback**: Revert các định nghĩa job Jenkins.
* **Tiêu chí Hoàn thành**: Thực thi dry-run build và triển khai tự động thành công.
* **Trạng thái**: Chờ `WP-009`

---

### `WP-011`: Triển khai Cơ sở Dữ liệu Quan hệ & Stateful (MySQL & MongoDB)
* **Mô tả**: Cấp phát các instance cơ sở dữ liệu MySQL và MongoDB sẵn sàng cao với chính sách vòng đời sao lưu PITR 30 ngày.
* **Yêu cầu Liên quan**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md), [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **Rủi ro Liên quan**: `RSK-DAT-001`, `RSK-OPS-001`
* **Phụ thuộc**: `WP-004`, `WP-009`, Giải quyết ADR Giai đoạn 0
* **Đầu vào**: Chỉ số định kích thước cơ sở dữ liệu, các key mã hóa KMS.
* **Đầu ra**: Các cluster cơ sở dữ liệu Multi-AZ với tự động nhân bản snapshot.
* **Vai trò Chịu trách nhiệm**: Quản trị viên Cơ sở Dữ liệu (DBA)
* **Xác minh**: Kiểm thử failover Multi-AZ và khôi phục point-in-time recovery.
* **Phương pháp Rollback**: Xóa các instance cơ sở dữ liệu qua Terraform.
* **Tiêu chí Hoàn thành**: Chạy thử nghiệm khôi phục sao lưu PITR được xác minh.
* **Trạng thái**: Chờ Giải quyết ADR Giai đoạn 0

---

### `WP-012`: Triển khai Cache & Truyền tin nhắn (Redis & RabbitMQ)
* **Mô tả**: Cấp phát các cluster Redis cache và RabbitMQ message broker sẵn sàng cao trên 3 AZs.
* **Yêu cầu Liên quan**: [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md), [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md)
* **Rủi ro Liên quan**: `RSK-OPS-001`, `RSK-UNC-001`
* **Phụ thuộc**: `WP-004`, `WP-009`, Giải quyết ADR Giai đoạn 0
* **Đầu vào**: Yêu cầu RAM cache, quy cách RabbitMQ quorum queue.
* **Đầu ra**: Các endpoint cluster Redis và RabbitMQ Multi-AZ.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Trưởng Hạ tầng
* **Xác minh**: Kiểm thử publish/subscribe tin nhắn giả lập và failover cache.
* **Phương pháp Rollback**: Hủy cấp phát các cluster cache và broker qua Terraform / Helm.
* **Tiêu chí Hoàn thành**: Độ trễ Redis sub-millisecond và failover 0 mất tin nhắn.
* **Trạng thái**: Chờ Giải quyết ADR Giai đoạn 0

---

### `WP-013`: Triển khai Cluster Phát hiện Dịch vụ & Cấu hình Động Nacos
* **Mô tả**: Triển khai Nacos cluster multi-replica trên EKS trong các subnet private backed bởi tầng cơ sở dữ liệu MySQL (`FUN-009`).
* **Yêu cầu Liên quan**: [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md)
* **Rủi ro Liên quan**: `RSK-ARC-002`
* **Phụ thuộc**: `WP-007`, `WP-011`
* **Đầu vào**: Helm chart Nacos, các tham số kết nối MySQL.
* **Đầu ra**: Nacos cluster 3-node hoạt động có nạp cấu hình động.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Trưởng Ứng dụng
* **Xác minh**: Kiểm thử đăng ký dịch vụ và cập nhật cấu hình động.
* **Phương pháp Rollback**: Xóa Nacos StatefulSet.
* **Tiêu chí Hoàn thành**: Xác minh đẩy cấu hình động tới các pod microservice.
* **Trạng thái**: Chờ `WP-011`

---

### `WP-014`: Onboarding & Kiểm thử Tải Microservice Thử nghiệm Kỹ thuật
* **Mô tả**: Onboard bộ 5 microservice thử nghiệm (API, worker, DB, cache, ingress) và thực thi kiểm thử tải giả lập.
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md), [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **Rủi ro Liên quan**: `RSK-SCL-001`, `RSK-CST-001`
* **Phụ thuộc**: `WP-010`, `WP-011`, `WP-012`, `WP-013`
* **Đầu vào**: Ảnh container ứng dụng thử nghiệm, script kiểm thử tải Locust / k6.
* **Đầu ra**: Báo cáo Benchmark Nghiệm thu Thử nghiệm Kỹ thuật.
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm SRE / Trưởng nhóm DevOps
* **Xác minh**: Thời gian phản hồi tự động mở rộng node Karpenter dưới đợt bùng nổ 100% tải.
* **Phương pháp Rollback**: Gỡ bỏ các microservice thử nghiệm.
* **Tiêu chí Hoàn thành**: Ký duyệt [`GATE-06`](ACCEPTANCE-GATES.md).
* **Trạng thái**: Chờ `WP-013`

---

### `WP-015`: Cấp phát Tài khoản AWS Production & EKS Cluster Production
* **Mô tả**: Cấp phát `DataBlue-Prod-Account` chuyên trách và EKS cluster Production sau khi CAB phê duyệt.
* **Yêu cầu Liên quan**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md), [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md)
* **Rủi ro Liên quan**: `RSK-SEC-003`
* **Phụ thuộc**: `WP-014`, [`GATE-07`](ACCEPTANCE-GATES.md) (Phê duyệt CAB)
* **Đầu vào**: Modules Terraform Production, ticket ủy quyền CAB.
* **Đầu ra**: Tài khoản AWS Production cô lập và EKS Multi-AZ Cluster.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Trưởng Hạ tầng
* **Xác minh**: Kiểm toán cô lập môi trường Production.
* **Phương pháp Rollback**: `terraform destroy` trên stack Production (yêu cầu từ bỏ của CAB).
* **Tiêu chí Hoàn thành**: Ký duyệt [`GATE-07`](ACCEPTANCE-GATES.md).
* **Trạng thái**: Chờ `GATE-07`

---

### `WP-016`: Gia cố Bảo mật Production, Vault Lock & Nhân bản Sao lưu
* **Mô tả**: Bật AWS Backup Vault Lock (bảo vệ chống ransomware) và copy sao lưu S3 xuyên tài khoản tới Tài khoản Security.
* **Yêu cầu Liên quan**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **Rủi ro Liên quan**: `RSK-SEC-003`, `RSK-DAT-002`
* **Phụ thuộc**: `WP-015`
* **Đầu vào**: Chính sách S3 bucket Tài khoản Security, cấu hình AWS Backup vault.
* **Đầu ra**: Vault sao lưu production bất biến với tự động copy xuyên tài khoản.
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm Bảo mật Đám mây
* **Xác minh**: Kiểm thử xác minh bản sao sao lưu xuyên tài khoản.
* **Phương pháp Rollback**: Cập nhật quy tắc vòng đời S3 bucket.
* **Tiêu chí Hoàn thành**: Xác minh bản sao sao lưu bất biến trong Tài khoản AWS Security.
* **Trạng thái**: Chờ `WP-015`

---

### `WP-017`: Thực thi Các Làn Di chuyển Microservice (Làn 1 đến 5)
* **Mô tả**: Onboard ~40 microservices vào Production qua 5 làn di chuyển tuân thủ các tiêu chí đầu vào/đầu ra của từng làn.
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Rủi ro Liên quan**: `RSK-DEL-001`
* **Phụ thuộc**: `WP-015`, `WP-016`
* **Đầu vào**: Danh mục microservice, lịch trình làn di chuyển.
* **Đầu ra**: 100% microservices được triển khai lên môi trường Production.
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm DevOps / Trưởng nhóm Di chuyển
* **Xác minh**: Kiểm thử giao dịch nghiệp vụ giả lập end-to-end theo từng làn.
* **Phương pháp Rollback**: Thực thi các playbook rollback theo làn (`ROLLBACK-STRATEGY.md`).
* **Tiêu chí Hoàn thành**: Ký duyệt [`GATE-09`](ACCEPTANCE-GATES.md) theo từng làn.
* **Trạng thái**: Chờ `WP-016`

---

### `WP-018`: Sẵn sàng Production, Kiểm thử Chaos & Diễn tập Failover DR
* **Mô tả**: Thực thi giả lập node crash, sự cố AZ, failover cơ sở dữ liệu, và diễn tập failover DR xuyên vùng.
* **Yêu cầu Liên quan**: [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Rủi ro Liên quan**: `RSK-AVL-001`, `RSK-DAT-002`
* **Phụ thuộc**: `WP-017`
* **Đầu vào**: Kịch bản kiểm thử Chaos Mesh, runbook failover DR.
* **Đầu ra**: Báo cáo Xác minh Sẵn sàng Production & Khôi phục Thảm họa.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Trưởng Đám mây / Trưởng nhóm SRE
* **Xác minh**: Xác minh tuân thủ SLA RTO và RPO trong sự cố giả lập.
* **Phương pháp Rollback**: Khôi phục định tuyến lưu lượng vùng chính.
* **Tiêu chí Hoàn thành**: Ký duyệt [`GATE-08`](ACCEPTANCE-GATES.md).
* **Trạng thái**: Chờ `WP-017`

---

### `WP-019`: Tối ưu Chi phí FinOps, Rightsizing & Quản trị Ngân sách
* **Mô tả**: Phân tích baseline metric production, áp dụng EC2/Compute Savings Plans, và thực thi rightsizing.
* **Yêu cầu Liên quan**: [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **ADR Liên quan**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md)
* **Rủi ro Liên quan**: `RSK-CST-001`
* **Phụ thuộc**: `WP-017`
* **Đầu vào**: Metrics AWS Cost Explorer, baselines mức độ sử dụng node 30 ngày.
* **Đầu ra**: Báo cáo Tối ưu Chi phí FinOps & Cam kết Savings Plans Đang Hoạt động.
* **Vai trò Chịu trách nhiệm**: Trưởng nhóm FinOps
* **Xác minh**: Kiểm tra độ lệch chi tiêu AWS thực tế so với mô hình chi phí (trong khoảng ±15%).
* **Phương pháp Rollback**: Không áp dụng (Điều chỉnh chính sách FinOps).
* **Tiêu chí Hoàn thành**: 100% tài nguyên AWS được gắn tag CostCenter hợp lệ.
* **Trạng thái**: Chờ `WP-017`

---

### `WP-020`: Bàn giao Vận hành, Runbooks & Triển khai Thang Phản ứng Hỗ trợ
* **Mô tả**: Bàn giao runbook vận hành, tổ chức đào tạo SRE, và thực thi bàn giao quyền truy cập cho đội ngũ vận hành doanh nghiệp.
* **Yêu cầu Liên quan**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`AGENTS.md`](../../AGENTS.md)
* **ADR Liên quan**: Tất cả các ADRs
* **Rủi ro Liên quan**: `RSK-OPS-001`, `RSK-OPS-002`
* **Phụ thuộc**: `WP-018`, `WP-019`
* **Đầu vào**: Sổ tay vận hành, runbooks ứng cứu sự cố.
* **Đầu ra**: Biên bản Nghiệm thu Bàn giao Vận hành đã ký và Ma trận Hỗ trợ.
* **Vai trò Chịu trách nhiệm**: Kiến trúc sư Trưởng Hạ tầng / Trưởng nhóm Vận hành
* **Xác minh**: Diễn tập giả lập hỗ trợ vận hành.
* **Phương pháp Rollback**: Giao gia hỗ trợ từ đội ngũ dự án hypercare.
* **Tiêu chí Hoàn thành**: Ký duyệt [`GATE-10`](ACCEPTANCE-GATES.md).
* **Trạng thái**: Chờ `WP-019`
