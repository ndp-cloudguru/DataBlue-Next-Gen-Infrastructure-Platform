# Kế hoạch Xác minh Hiệu năng & Mở rộng (Performance & Scaling Validation Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Quy cách Xác minh Hiệu năng & Mở rộng** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng các yêu cầu [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) và [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md):
* Các kiểm thử tải giả lập và benchmark tự động mở rộng node được thực thi đối với ứng dụng Thử nghiệm Kỹ thuật (`WP-014`).
* **Không kết quả kiểm thử nào được đánh dấu trước là đã đạt (passed)**. Tất cả các mục xác minh hiệu năng hiện duy trì trạng thái `Pending`.

---

## 2. Ma trận Xác minh Hiệu năng & Mở rộng

| Danh mục Hiệu năng | Yêu cầu / ADR Quản trị | Phạm vi Kiểm toán Xác minh | Tiêu chí Đạt Chấp nhận Mục tiêu | Mã Bằng chứng Bắt buộc | Chủ sở hữu Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Độ trễ Ingress (P95)** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md) | Thời gian phản hồi ALB Ingress API dưới tải cơ sở | Độ trễ P95 < 200ms tại ranh giới đầu vào ALB | `EVD-PRF-001` | Trưởng nhóm Hiệu năng | `Pending` |
| **2. Độ trễ Ingress (P99)** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md) | Thời gian phản hồi ALB Ingress API dưới tải cơ sở | Độ trễ P99 < 500ms tại ranh giới đầu vào ALB | `EVD-PRF-001` | Trưởng nhóm Hiệu năng | `Pending` |
| **3. Dung lượng Tải Bùng nổ** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | Đợt bùng nổ tải k6 phân tán (200% băng thông đỉnh) | 0 lỗi HTTP 500 dưới đợt bùng nổ 200% tải | `EVD-PRF-001` | Trưởng nhóm Hiệu năng | `Pending` |
| **4. Tự động Mở rộng Pod (HPA)** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | Mở rộng replica pod HPA khi có kích hoạt 70% CPU | Mở rộng số lượng replica pod trong < 30 giây | `EVD-SCL-001` | Trưởng nhóm SRE | `Pending` |
| **5. Tự động Mở rộng Node** | [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | Cấp phát EC2 node Karpenter JIT | Node mới được cấp phát & `Ready` trong < 60s | `EVD-SCL-001` | Trưởng nhóm SRE | `Pending` |
| **6. Độ trễ Đọc Cơ sở Dữ liệu** | [`NFR-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | Hiệu năng truy vấn endpoint Read-Replica MySQL | Độ trễ truy vấn DB P95 < 10ms | `EVD-DB-003` | Trưởng nhóm DBA | `Pending` |
| **7. Độ trễ Redis Cache** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | Phản hồi đọc/ghi cluster ElastiCache Redis | Độ trễ phản hồi lệnh Redis < 2ms | `EVD-CACHE-001` | Trưởng nhóm Hạ tầng | `Pending` |

---

## 3. Giao thức Thực thi Kiểm thử Benchmark Mở rộng

### Kiểm thử PRF-01 — Benchmark Độ trễ Cấp phát Node Karpenter
* **Quy trình**: Bơm đồng thời 50 yêu cầu tài nguyên pod unschedulable vào EKS Test Cluster.
* **Metric**: Thời gian trôi qua giữa trạng thái `PodScheduled: False` và trạng thái `NodeReady: True`.
* **Tiêu chí Đạt**: Karpenter cấp phát EC2 instance node được yêu cầu và đạt trạng thái `Ready` trong < 60 giây (`EVD-SCL-001`).

### Kiểm thử PRF-02 — Kiểm thử Tải 10,000 Người dùng Đồng thời
* **Quy trình**: Thực thi kiểm thử tải k6 phân tán 15 phút giả lập 10,000 người dùng ảo đồng thời nhắm tới các endpoint API microservice.
* **Tiêu chí Đạt**: Tỷ lệ lỗi < 0.01%, độ trễ ALB P95 < 200ms (`EVD-PRF-001`).
