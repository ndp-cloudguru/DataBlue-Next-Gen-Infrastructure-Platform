# Ma trận Truy xuất Yêu cầu (Requirement Traceability Matrix): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Ma trận Truy xuất Yêu cầu (RTM)** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Nó ánh xạ từng yêu cầu (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`) từ [`REQUIREMENTS-REGISTER.md`](../01-requirements/REQUIREMENTS-REGISTER.md) tới các Quyết định Kiến trúc (`ADR`), Gói Công việc Triển khai (`WP`), Tài liệu Miền Xác minh Target, Mã Bằng chứng, Chủ sở hữu Chịu trách nhiệm, và Trạng thái Xác minh.

---

## 2. Ma trận Truy xuất Yêu cầu Tổng thể

| Mã Yêu cầu | Tóm tắt Yêu cầu | ADR Quản trị | Gói Công việc (WP) | Tài liệu Xác minh Mục tiêu | Mã Bằng chứng | Chủ sở hữu Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`BUS-001`** | ~40 Microservices trên 5-6 Hệ thống Nghiệp vụ | [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | `WP-001`, `WP-005`, `WP-017` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-PRF-001` | Trưởng nhóm Kiến trúc Ứng dụng | `Pending` |
| **`BUS-002`** | Tự động hóa Triển khai Ứng dụng | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-007`, `WP-010` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-CICD-001` | Trưởng nhóm DevOps | `Pending` |
| **`BUS-003`** | Phân tách Môi trường Test & Production | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md) | `WP-002`, `WP-005`, `WP-015` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-ENV-001` | Kiến trúc sư Hạ tầng | `Pending` |
| **`BUS-004`** | Ước tính Chi phí AWS Chi tiết | Tất cả ADRs | `WP-019` | [`COST-VALIDATION.md`](COST-VALIDATION.md) | `EVD-CST-001` | Trưởng nhóm FinOps | `Pending` |
| **`FUN-001`** | Nền tảng Điều phối Container Kubernetes | [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | `WP-005`, `WP-015` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-K8S-001` | Kiến trúc sư Đám mây | `Pending` |
| **`FUN-002`** | Tích hợp Mã nguồn GitLab & MR Trigger | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-010` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-CICD-002` | Kỹ sư DevOps | `Pending` |
| **`FUN-003`** | Jenkins CI Worker Build & Quét Ảnh | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-010` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-001` | Kỹ sư DevOps | `Pending` |
| **`FUN-004`** | Quản lý Cấu hình Ansible Playbook | [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | `WP-010` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-CICD-003` | Kỹ sư DevOps | `Pending` |
| **`FUN-005`** | Triển khai Cơ sở Dữ liệu Quan hệ (MySQL) | [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | `WP-011` | [`BACKUP-RESTORE-VALIDATION.md`](BACKUP-RESTORE-VALIDATION.md) | `EVD-DB-001` | Trưởng nhóm DBA | `Pending` |
| **`FUN-006`** | Triển khai Message Queue Broker (RabbitMQ) | [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md) | `WP-012` | [`HA-VALIDATION.md`](HA-VALIDATION.md) | `EVD-MQ-001` | Trưởng nhóm Kiến trúc Ứng dụng | `Pending` |
| **`FUN-007`** | Triển khai Document Store Database (MongoDB) | [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md) | `WP-011` | [`BACKUP-RESTORE-VALIDATION.md`](BACKUP-RESTORE-VALIDATION.md) | `EVD-DB-002` | Trưởng nhóm DBA | `Pending` |
| **`FUN-008`** | Triển khai Tầng In-Memory Cache (Redis) | [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | `WP-012` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-CACHE-001` | Trưởng nhóm Kiến trúc Hạ tầng | `Pending` |
| **`FUN-009`** | Service Discovery & Trung tâm Cấu hình (Nacos) | [`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md) | `WP-013` | [`HA-VALIDATION.md`](HA-VALIDATION.md) | `EVD-NC-001` | Trưởng nhóm Kiến trúc Ứng dụng | `Pending` |
| **`NFR-001`** | Sẵn sàng Cao & Chịu lỗi Multi-AZ | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | `WP-004`, `WP-005`, `WP-018` | [`HA-VALIDATION.md`](HA-VALIDATION.md) | `EVD-HA-001` | Trưởng nhóm SRE | `Pending` |
| **`NFR-002`** | Tự động Mở rộng Động (Pod & Worker Node) | [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | `WP-005`, `WP-014` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-SCL-001` | Trưởng nhóm SRE | `Pending` |
| **`NFR-003`** | Khôi phục Thảm họa & Thời hạn Lưu trữ Sao lưu | [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | `WP-011`, `WP-016`, `WP-018` | [`DR-VALIDATION.md`](DR-VALIDATION.md) | `EVD-DR-001` | Kiến trúc sư Trưởng Đám mây | `Pending` |
| **`NFR-004`** | Mục tiêu SLA Hiệu năng & Băng thông | [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | `WP-014` | [`PERFORMANCE-VALIDATION.md`](PERFORMANCE-VALIDATION.md) | `EVD-PRF-002` | Trưởng nhóm Hiệu năng | `Pending` |
| **`SEC-001`** | IAM Identity Center, IRSA & Phân quyền RBAC | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md) | `WP-003`, `WP-009` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-002` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **`SEC-002`** | Cô lập Tài khoản & Vành đai Mạng | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md) | `WP-002`, `WP-004` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-003` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **`SEC-003`** | Mã hóa Dữ liệu at Rest & In Transit | [`ADR-011`](../03-decisions/ADR-011-secrets-management.md) | `WP-003`, `WP-016` | [`SECURITY-VALIDATION.md`](SECURITY-VALIDATION.md) | `EVD-SEC-004` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **`OPS-001`** | Giám sát Metrics Máy chủ & Microservice | [`ADR-012`](../03-decisions/ADR-012-observability.md) | `WP-008` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-OPS-001` | Trưởng nhóm Vận hành | `Pending` |
| **`OPS-002`** | Gom Log Tập trung & Lưu trữ Dài hạn | [`ADR-012`](../03-decisions/ADR-012-observability.md) | `WP-008`, `WP-016` | [`ARCHITECTURE-CONFORMANCE.md`](ARCHITECTURE-CONFORMANCE.md) | `EVD-OPS-002` | Trưởng nhóm Vận hành | `Pending` |
| **`CST-001`** | Tối ưu Chi phí & Rightsizing | [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | `WP-019` | [`COST-VALIDATION.md`](COST-VALIDATION.md) | `EVD-CST-002` | Trưởng nhóm FinOps | `Pending` |
| **`CST-002`** | Tagging Tài chính & Quản trị Ngân sách | [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md) | `WP-002`, `WP-019` | [`COST-VALIDATION.md`](COST-VALIDATION.md) | `EVD-CST-003` | Trưởng nhóm FinOps | `Pending` |
