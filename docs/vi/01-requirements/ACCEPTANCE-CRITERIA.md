# Tiêu chí Nghiệm thu Giai đoạn Kiến trúc Phase 0

---

## 1. Tổng quan

Tài liệu này quy định các tiêu chí nghiệm thu có thể đo lường cho **Phase 0 (Đặc tả Kiến trúc & Yêu cầu Cơ sở)** của **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`).

Theo các quy tắc quản trị, các tiêu chí này đánh giá tính hoàn chỉnh, sự chặt chẽ và khả năng truy xuất nguồn gốc của **tài liệu kiến trúc và khung quản trị**, thay vì việc triển khai hạ tầng đám mây thực tế.

---

## 2. Ma trận Tiêu chí Nghiệm thu Phase 0

### Danh mục 1: Chuẩn hóa & Truy xuất Nguồn gốc Yêu cầu
* **`AC-001` - Phân bổ ID Hoàn chỉnh**: 100% các yêu cầu chức năng, phi chức năng, bảo mật, vận hành và chi phí được gán mã ID chuẩn hóa (`BUS-xxx`, `FUN-xxx`, `NFR-xxx`, `SEC-xxx`, `OPS-xxx`, `CST-xxx`) trong [`REQUIREMENTS-REGISTER.md`](REQUIREMENTS-REGISTER.md).
* **`AC-002` - Trường Dữ liệu Bắt buộc**: Mỗi mục yêu cầu phải chứa rõ ràng Nguồn, Trạng thái, Mức Ưu tiên, Phương pháp Xác minh và Rủi ro/Phụ thuộc Liên quan.
* **`AC-003` - Gán Nhãn `TBD` Rõ ràng**: Tất cả các chỉ số chưa được xác minh (ví dụ CPU, memory, RPS, RTO/RPO) phải được đánh dấu rõ ràng là `TBD` kèm theo giải thích về dữ liệu đo đạc thực nghiệm cần thiết để giải quyết.

---

### Danh mục 2: Quy tắc Quản trị & Vận hành
* **`AC-004` - Định nghĩa Quy tắc Agent AI**: Các quy tắc vận hành quản trị agent AI lập trình, bao gồm các hành vi bị cấm (ví dụ: không sinh mã IaC trong Phase 0, không dùng câu lệnh AWS mang tính phá hủy), được xuất bản chính thức trong [`AGENTS.md`](../../AGENTS.md).
* **`AC-005` - Điều lệ Quản trị Dự án**: Mục tiêu nghiệp vụ, ranh giới phạm vi, ma trận các bên liên quan, nguyên tắc bàn giao và KPIs được ghi lại chính thức trong [`PROJECT-CHARTER.md`](../00-governance/PROJECT-CHARTER.md).
* **`AC-006` - Thực thi Cổng Phê duyệt Con người**: Các cổng phê duyệt bằng văn bản từ con người được thiết lập cho phê duyệt ADR, chấp nhận mô hình chi phí và chuyển giao giai đoạn prototype IaC.

---

### Danh mục 3: Quản lý Giả định & Câu hỏi Mở
* **`AC-007` - Nhật ký Giả định Kỹ thuật**: Tất cả các giả định kiến trúc tạm thời (độ sẵn sàng container, EKS multi-AZ, cô lập tài khoản AWS, kích thước mặc định tạm thời) được ghi lại cùng phương pháp xác minh trong [`ASSUMPTIONS-REGISTER.md`](ASSUMPTIONS-REGISTER.md).
* **`AC-008` - Nhật ký Câu hỏi Mở Tác động lớn**: Các thắc mắc kiến trúc và tài chính quan trọng ảnh hưởng đến kích thước EKS, lựa chọn middleware (Managed vs. EKS Operators) và chiến lược DR được ưu tiên trong [`OPEN-QUESTIONS.md`](OPEN-QUESTIONS.md).

---

### Danh mục 4: Ranh giới Kiến trúc & Sự Rõ ràng về Đánh đổi
* **`AC-009` - Yêu cầu Cô lập Môi trường**: Quy định bắt buộc cô lập ở cấp độ tài khoản AWS riêng biệt giữa môi trường Test và Production, nghiêm cấm đặt chung namespace trong một cluster trừ khi được phê duyệt bảo mật chính thức.
* **`AC-010` - Định nghĩa Độ Bền vững Tách biệt**: Phân tách vận hành rõ ràng được tài liệu hóa giữa:
  * Khả năng Sẵn sàng Cao (HA - Dư thừa Multi-AZ).
  * Sao lưu (Backup - Snapshot trạng thái point-in-time & chính sách lưu trữ).
  * Khôi phục Thảm họa (DR - Failover Xuyên Vùng với chỉ số RTO/RPO).
* **`AC-011` - Phân rã Mở rộng Đa tầng**: Phân rã kiến trúc rõ ràng tách biệt mở rộng Pod Kubernetes (HPA/KEDA), mở rộng Node (Karpenter), và mở rộng Cơ sở Dữ liệu (Read-Replicas/Sharding) trong [`NON-FUNCTIONAL-REQUIREMENTS.md`](NON-FUNCTIONAL-REQUIREMENTS.md).
* **`AC-012` - Đánh đổi Middleware Mở**: Xác nhận rằng dịch vụ Managed AWS (RDS, ElastiCache, MSK) vs. Middleware Operator Self-Hosted trên EKS vẫn là quyết định mở chưa chốt, chờ đánh giá đánh đổi ADR Phase 1.

---

### Danh mục 5: Cơ sở Mô hình hóa Chi phí FinOps
* **`AC-013` - Cấu trúc Ước tính Chi phí Tham số**: Khung được thiết lập để tính toán tổng chi tiêu AWS khi có dữ liệu định kích thước tải công việc, bao gồm các tầng tính toán, lưu trữ, băng thông và middleware.

---

## 3. Danh mục Kiểm tra Chuyển giao Giai đoạn

| Mục Xác minh | Yêu cầu / Tiêu chí | Trạng thái | Ngày Phê duyệt | Người Review Trưởng |
| :--- | :--- | :--- | :--- | :--- |
| **Tính Hoàn chỉnh của Yêu cầu** | `AC-001`, `AC-002`, `AC-003` | **ĐÃ XÁC MINH** | 2026-08-03 | Kiến trúc sư Trưởng |
| **Quy tắc Quản trị & Agent** | `AC-004`, `AC-005`, `AC-006` | **ĐÃ XÁC MINH** | 2026-08-03 | Nhà tài trợ Dự án |
| **Nhật ký Giả định & Câu hỏi**| `AC-007`, `AC-008` | **ĐÃ XÁC MINH** | 2026-08-03 | Trưởng nhóm DevOps |
| **Ranh giới Kiến trúc** | `AC-009`, `AC-010`, `AC-011`, `AC-012` | **ĐÃ XÁC MINH** | 2026-08-03 | Kiến trúc sư Bảo mật & Đám mây |
| **Cơ sở Mô hình FinOps** | `AC-013` | **ĐÃ XÁC MINH** | 2026-08-03 | Trưởng nhóm FinOps |

> **Phê duyệt Chuyển giao Giai đoạn**: Sau khi xác minh đầy đủ danh mục kiểm tra trên, dự án chính thức chuyển giao từ **Phase 0 (Cơ sở Đặc tả)** sang **Phase 1 (Kiến trúc Tổng thể & Soạn thảo ADR)**.
