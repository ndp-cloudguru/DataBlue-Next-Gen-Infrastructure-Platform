# Kế hoạch Xác minh Sẵn sàng Cao (HA Validation Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Kế hoạch Xác minh Sẵn sàng Cao (HA) & Chịu lỗi** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng yêu cầu [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md):
* Các cam kết sẵn sàng cao được xác minh thông qua các đợt giả lập EC2 worker node bị crash, pod eviction, và sự cố mạng Availability Zone.
* **Không kết quả kiểm thử nào được đánh dấu trước là đã đạt (passed)**. Tất cả các mục xác minh HA hiện duy trì trạng thái `Pending`.

---

## 2. Ma trận Xác minh Sẵn sàng Cao (HA)

| Tầng HA | Yêu cầu / ADR Quản trị | Phạm vi Kiểm toán Xác minh | Tiêu chí Đạt Chấp nhận Mục tiêu | Mã Bằng chứng Bắt buộc | Chủ sở hữu Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Control Plane HA** | [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | etcd quorum multi-AZ của AWS EKS managed control plane | EKS API server hoạt động bình thường khi mất 1 AZ | `EVD-HA-001` | Kiến trúc sư Đám mây | `Pending` |
| **2. Worker Node HA** | [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | Phân tán các EC2 worker nodes trên 3 AZs | Các node pool được cân bằng trên AZ-a, AZ-b, & AZ-c | `EVD-HA-001` | Trưởng nhóm SRE | `Pending` |
| **3. Phân tán Pod Topology**| [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md) | Pod Topology Spread Constraints (`topologyKey`) | Các pod ứng dụng phân bổ đều trên 3 AZs | `EVD-HA-001` | Trưởng nhóm DevOps | `Pending` |
| **4. MySQL Database HA** | [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | Chấm dứt instance primary Amazon RDS MySQL Multi-AZ | Failover tự động sang instance standby (< 60s) | `EVD-HA-002` | Trưởng nhóm DBA | `Pending` |
| **5. Redis Cache HA** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | Failover node primary nhân bản ElastiCache Redis | Failover primary tự động & cập nhật endpoint (< 30s) | `EVD-HA-003` | Trưởng nhóm Hạ tầng | `Pending` |
| **6. RabbitMQ Broker HA** | [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md) | Chấm dứt leader Quorum Queue 3-node RabbitMQ | Bầu chọn lại leader quorum queue với 0 mất dữ liệu | `EVD-MQ-001` | Kiến trúc sư Ứng dụng | `Pending` |
| **7. Nacos Cluster HA** | [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md) | Chấm dứt node Nacos Raft cluster | Bầu chọn lại Raft leader & sẵn sàng cấu hình | `EVD-NC-001` | Kiến trúc sư Ứng dụng | `Pending` |

---

## 3. Giao thức Kiểm thử Bơm Lỗi Sẵn sàng Cao (Fault Injection)

### Kiểm thử HA-01 — Giả lập Hố đen Mạng Availability Zone
* **Quy trình**: Bơm đợt gián đoạn mạng AWS Fault Injection Simulator (FIS) chặn toàn bộ lưu lượng vào/ra tới Availability Zone `AZ-a`.
* **Tiêu chí Đạt**:
  1. Các pod replica EKS trong `AZ-b` và `AZ-c` xử lý 100% lưu lượng ingress.
  2. Kiểm tra sức khỏe ALB loại bỏ các target trong `AZ-a` trong vòng 15 giây.
  3. Zero mất mát giao dịch người dùng (`EVD-HA-001`).

### Kiểm thử HA-02 — Diễn tập Failover MySQL Master Multi-AZ
* **Quy trình**: Kích hoạt reboot bắt buộc kèm failover trên instance cơ sở dữ liệu primary RDS MySQL (`FUN-005`).
* **Tiêu chí Đạt**: Instance Standby ở AZ thứ hai được thăng cấp thành Primary; endpoint DNS CNAME được cập nhật; các pod microservice tự động kết nối lại trong < 60 giây (`EVD-HA-002`).
