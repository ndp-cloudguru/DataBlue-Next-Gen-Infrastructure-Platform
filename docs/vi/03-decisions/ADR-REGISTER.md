# Sổ ký Quyết định Kiến trúc (ADR Register): Nền tảng AWS Kubernetes DataBlue

---

## 1. Tổng quan

Tài liệu này đóng vai trò là sổ ký danh mục master cho tất cả các **Hồ sơ Quyết định Kiến trúc (Architecture Decision Records - ADRs)** cho **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`).

Theo các quy tắc Stage 3:
* Tất cả các ADR hiện tại ở trạng thái **`Proposed` (Đề xuất)** hoặc **`Deferred` (Tạm hoãn)**.
* Không có quyết định nào được đánh dấu `Accepted` nếu chưa có phê duyệt chính thức từ con người.

---

## 2. Danh mục Master ADR

| Mã ADR | Tiêu đề Quyết định | Trạng thái | Yêu cầu Chính | Rủi ro Chính | Phụ thuộc Quyết định | Bằng chứng Xác minh Cần thiết | Giai đoạn Xem xét Mục tiêu | Cập nhật Cuối |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| [`ADR-001`](ADR-001-aws-account-strategy.md) | Chiến lược Tài khoản AWS | `Proposed` | `BUS-003`, `SEC-002` | `RSK-SEC-003` | Không | Review thiết kế AWS Landing Zone | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-002`](ADR-002-environment-isolation.md) | Mô hình Cô lập Môi trường | `Proposed` | `BUS-003`, `SEC-002`, `NFR-001` | `RSK-SEC-003` | `ADR-001` | Kiểm toán bảo mật đa tài khoản EKS | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-003`](ADR-003-kubernetes-platform.md) | Engine Nền tảng Kubernetes | `Proposed` | `BUS-001`, `FUN-001`, `OPS-001` | `RSK-OPS-001` | `ADR-001`, `ADR-002` | Phê duyệt SLA control plane EKS | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-004`](ADR-004-cicd-operating-model.md) | Mô hình Vận hành CI/CD | `Proposed` | `BUS-002`, `FUN-002`–`FUN-004` | `RSK-SEC-001`, `RSK-ARC-001` | `ADR-001`, `ADR-011` | Chạy thử interface pipeline Jenkins-Ansible | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-005`](ADR-005-node-autoscaling.md) | Engine Mở rộng Node Tự động | `Proposed` | `NFR-002`, `CST-001` | `RSK-UNC-001`, `RSK-SCL-001` | `ADR-003` | Benchmark độ trễ cấp phát node Karpenter | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-006`](ADR-006-mysql-deployment.md) | Chiến lược Triển khai MySQL | `Deferred` | `FUN-005`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | Chỉ số IOPS & kích thước DB microservice | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-007`](ADR-007-redis-deployment.md) | Chiến lược Triển khai Redis | `Deferred` | `FUN-008`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | Đo đạc dung lượng bộ nhớ & IOPS cache | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-008`](ADR-008-rabbitmq-deployment.md) | Chiến lược Triển khai RabbitMQ | `Deferred` | `FUN-006`, `CST-001` | `RSK-UNC-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | Chỉ số băng thông tin nhắn & độ sâu hàng chờ | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-009`](ADR-009-mongodb-deployment.md) | Chiến lược Triển khai MongoDB | `Deferred` | `FUN-007`, `CST-001` | `RSK-DAT-001`, `RSK-OPS-001` | `ADR-001`, `ADR-003` | Kiểm toán tương thích driver/truy vấn DocumentDB | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-010`](ADR-010-nacos-deployment.md) | Chiến lược Triển khai Nacos | `Proposed` | `FUN-009`, `OPS-001` | `RSK-ARC-002` | `ADR-003` | Kiểm thử phân giải DNS Nacos xuyên namespace | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-011`](ADR-011-secrets-management.md) | Topo Quản lý Secrets | `Proposed` | `SEC-001`, `FUN-002`–`FUN-004` | `RSK-SEC-001`, `RSK-SEC-002` | `ADR-001`, `ADR-003` | Kiểm thử đồng bộ External Secrets Operator | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-012`](ADR-012-observability.md) | Kiến trúc Khả năng Quan sát | `Proposed` | `OPS-001`, `OPS-002` | `RSK-CST-002`, `RSK-OPS-002` | `ADR-001`, `ADR-003` | Benchmark chuyển tiếp log Fluent Bit | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-013`](ADR-013-backup-strategy.md) | Chiến lược Sao lưu | `Proposed` | `NFR-003`, `OPS-002` | `RSK-DAT-002` | `ADR-006`–`ADR-010` | Kiểm thử khôi phục tự động DB & Velero | Stage 3 / Phase 1 | 2026-08-03 |
| [`ADR-014`](ADR-014-disaster-recovery.md) | Chiến lược Khôi phục Thảm họa | `Deferred` | `NFR-003`, `CST-001` | `RSK-UNC-003`, `RSK-AVL-001` | `ADR-001`, `ADR-013` | Phê duyệt chỉ số mục tiêu RTO/RPO nghiệp vụ | Phase 1 / Phase 2 | 2026-08-03 |
| [`ADR-015`](ADR-015-infrastructure-as-code.md) | Mô hình Hạ tầng dạng Mã | `Proposed` | `BUS-002`, `AGENTS.md` | `RSK-DEL-001` | `ADR-001` | Kiểm toán linting & dry-run module Terraform | Stage 3 / Phase 1 | 2026-08-03 |
