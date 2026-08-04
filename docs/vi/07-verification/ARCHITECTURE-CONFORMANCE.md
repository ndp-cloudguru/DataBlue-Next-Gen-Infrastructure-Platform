# Kiểm toán Tuân thủ Kiến trúc (Architecture Conformance Audit): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Khung Kiểm toán Tuân thủ Kiến trúc** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Nó xác minh rằng việc triển khai hạ tầng AWS vật lý và cấu hình EKS cluster tuân thủ nghiêm ngặt theo [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) đã được duyệt và 15 Hồ sơ Quyết định Kiến trúc ([`ADR-REGISTER.md`](../03-decisions/ADR-REGISTER.md)).

---

## 2. Ma trận Kiểm toán Tuân thủ Kiến trúc ADR

| Mã ADR | Tiêu đề Quyết định Kiến trúc | Quy cách Tuân thủ Mục tiêu | Phương pháp Kiểm toán Tự động | Kiểm toán viên Chịu trách nhiệm | Trạng thái Tuân thủ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`ADR-001`** | AWS Landing Zone Đa Tài khoản | Phân tách các Account `Test`, `Prod`, `Shared`, `Security` | Kiểm toán AWS Organizations API & Control Tower | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **`ADR-002`** | Cô lập Môi trường & Cluster | 0 EKS clusters hoặc VPC peering dùng chung giữa Test & Prod | Kiểm toán AWS VPC Route Table & IAM Boundary | Kiến trúc sư Hạ tầng | `Pending` |
| **`ADR-003`** | Engine Kubernetes | Managed EKS (`v1.30+`) trên 3 Availability Zones | Bộ Kiểm thử Tuân thủ Kubernetes Sonobuoy | Kiến trúc sư Trưởng Đám mây | `Pending` |
| **`ADR-004`** | Bộ công cụ CI/CD Lai | GitLab + Jenkins + Ansible + Đồng bộ GitOps ArgoCD | Kiểm thử Thực thi Pipeline Dry-Run | Trưởng nhóm DevOps | `Pending` |
| **`ADR-005`** | Engine Tự động Mở rộng Node | Karpenter JIT NodePools với tỷ lệ kết hợp Spot/On-Demand | Kiểm thử áp lực lập lịch pod (< 60s mở rộng node) | Trưởng nhóm SRE | `Pending` |
| **`ADR-006`** | Cơ sở Dữ liệu Quan hệ (MySQL) | Triển khai Multi-AZ Primary/Standby | Xác minh AWS RDS API Multi-AZ | Trưởng nhóm DBA | `Deferred` (Chờ Giai đoạn 0) |
| **`ADR-007`** | In-Memory Cache (Redis) | Group Nhân bản ElastiCache Multi-AZ | Kiểm toán node nhân bản Redis INFO | Trưởng nhóm DBA | `Deferred` (Chờ Giai đoạn 0) |
| **`ADR-008`** | Message Broker (RabbitMQ) | Quorum Queues 3-Node trên 3 AZs | Kiểm toán quorum RabbitMQ Management API | Trưởng nhóm Kiến trúc Ứng dụng | `Deferred` (Chờ Giai đoạn 0) |
| **`ADR-009`** | Cơ sở Dữ liệu Tài liệu (MongoDB) | Replica Set 3 thành viên trên 3 AZs | Kiểm toán MongoDB `rs.status()` | Trưởng nhóm DBA | `Deferred` (Chờ Giai đoạn 0) |
| **`ADR-010`** | Service Discovery & Cấu hình Nacos | Raft cluster 3-Node trên EKS backed bởi MySQL | Kiểm toán trạng thái cluster Nacos Naming API | Trưởng nhóm Kiến trúc Ứng dụng | `Pending` |
| **`ADR-011`** | Kiến trúc Quản lý Secrets | AWS Secrets Manager + External Secrets Operator (ESO) | Kiểm thử đồng bộ ESO ClusterSecretStore | Kỹ sư Bảo mật | `Pending` |
| **`ADR-012`** | Nền tảng Observability | Prometheus/Grafana + Fluent Bit tới OpenSearch & S3 | Xác minh thu thập metric & đánh chỉ mục log | Trưởng nhóm Vận hành | `Pending` |
| **`ADR-013`** | Chiến lược & Thời hạn Sao lưu | DB PITR 30 Ngày + Velero S3 snapshots | Kiểm thử khôi phục sao lưu Velero dry-run | Trưởng nhóm Lưu trữ | `Pending` |
| **`ADR-014`** | Chiến lược Khôi phục Thảm họa | Failover vùng (Pilot Light / Standby) | Thực thi diễn tập failover DR vùng | Kiến trúc sư Trưởng Đám mây | `Deferred` (Chờ SLA) |
| **`ADR-015`** | Hạ tầng dạng Mã (IaC) | Terraform / OpenTofu mô-đun với remote S3 state | Quét phân tích tĩnh `checkov` & `tflint` | Trưởng nhóm Hạ tầng | `Pending` |

---

## 3. Giao thức Phát hiện Sai lệch Kiến trúc (Drift Detection)

1. **Quét Sai lệch Hạ tầng Hàng ngày**: Tự động thực thi Terraform plan (`terraform plan -detailed-exitcode`) được lên lịch hàng đêm trong pipeline CI/CD (`FUN-004`).
2. **Quét Sai lệch Manifest Cluster**: ArgoCD GitOps controller được đặt ở chế độ tự động đồng bộ (auto-sync) với thông báo cảnh báo out-of-sync gửi tới Slack (`ADR-004`).
3. **SLA Khắc phục Sai lệch**: Bất kỳ sai lệch kiến trúc chưa qua phê duyệt nào được phát hiện đều phải được tự động khôi phục trong vòng 1 giờ.
