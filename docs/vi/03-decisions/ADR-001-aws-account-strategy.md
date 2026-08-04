# ADR-001 — Chiến lược Tài khoản AWS (AWS Account Strategy)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Đám mây, Trưởng nhóm Bảo mật Doanh nghiệp
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Trưởng nhóm DevOps
* **Yêu cầu Liên quan**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-SEC-003` (Bán kính ảnh hưởng sự cố xuyên môi trường), `RSK-CST-001` (Phân bổ chi phí không kiểm soát)
* **Giả định Liên quan**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md) (Phân tách ở cấp độ Tài khoản AWS)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 4
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Nền tảng DataBlue phải lưu trữ ~40 microservices trên 5-6 hệ thống nghiệp vụ trong các môi trường Test và Production riêng biệt (`BUS-001`, `BUS-003`). Tổ chức yêu cầu kiểm soát truy cập bảo mật nghiêm ngặt, cô lập bán kính ảnh hưởng sự cố và phân bổ chi phí rõ ràng. Chúng ta cần quyết định cách cấu trúc ranh giới tài khoản AWS.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Cô lập Bảo mật & Bán kính Ảnh hưởng**: Ngăn ngừa sai lệch cấu hình hoặc sự cố ở môi trường Test làm ảnh hưởng đến Production (`SEC-002`).
2. **Phân bổ Chi phí & Tách biệt Hóa đơn**: Kế toán chi phí chính xác, không gây phiền hà theo từng môi trường (`CST-002`).
3. **Tự chủ Hạn ngạch Dịch vụ AWS**: Tránh giới hạn rate-limit API hoặc cạnh tranh hạn ngạch giữa tải công việc Test và Prod.
4. **Đồng bộ Tuân thủ & Kiểm toán**: Nhật ký kiểm toán tập trung (CloudTrail) với quyền quản trị đặc quyền tối thiểu.

---

## Các Hạn chế
* Phải vận hành natively bên trong hệ sinh thái đám mây AWS.
* Phải hỗ trợ quản trị tập trung qua AWS Organizations.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Một Tài khoản AWS Đơn lẻ (Đặt chung Test & Production)
* **Mô tả**: Tất cả tải công việc lưu trữ trong 1 Tài khoản AWS, dùng VPC và IAM tag để phân tách môi trường.
* **Ưu điểm**: Thiết lập ban đầu đơn giản; chi phí quản trị tài khoản thấp nhất.
* **Nhược điểm**: Rủi ro bán kính ảnh hưởng nghiêm trọng; dùng chung giới hạn API AWS; chính sách IAM phức tạp; rủi ro xóa nhầm tài nguyên production.
* **Tác động Bảo mật**: Yếu. Phân quyền nhầm lẫn xuyên môi trường rất dễ xảy ra.
* **Tác động Sẵn sàng**: Thấp. Đột biến tải môi trường Test có thể làm nghẽn API AWS ảnh hưởng tới Prod.
* **Tác động Mở rộng**: Trung bình. Dùng chung hạn ngạch tài khoản (ví dụ Elastic IPs, VPC limits).
* **Tác động Vận hành**: Rủi ro vận hành cao trong các thao tác quản trị.
* **Tác động Chi phí**: Khó cô lập chính xác chi phí tài nguyên dùng chung.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Cao nếu sau này buộc phải tách tài khoản.
* **Khả năng Đảo ngược**: Khó đảo ngược khi tài nguyên đã được cấp phát.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: `RSK-SEC-003` (Lỗ hổng rủi ro bán kính ảnh hưởng bảo mật nghiêm trọng).

### Phương án 2: Hai Tài khoản Tách biệt (Tài khoản Test & Prod Chuyên trách)
* **Mô tả**: Cấp phát hai tài khoản AWS riêng biệt (một cho Test, một cho Production).
* **Ưu điểm**: Cô lập môi trường tốt; ranh giới hóa đơn rõ ràng giữa Test và Prod.
* **Nhược điểm**: Thiếu tài khoản chuyên trách cho gom log bảo mật tập trung và bộ công cụ CI/CD dùng chung.
* **Tác động Bảo mật**: Trung bình-Cao. Cô lập môi trường tốt, nhưng log bảo mật vẫn nằm chung.
* **Tác động Sẵn sàng**: Cao. Sự cố môi trường Test không ảnh hưởng đến giới hạn API Production.
* **Tác động Mở rộng**: Cao. Hạn ngạch dịch vụ AWS độc lập theo từng môi trường.
* **Tác động Vận hành**: Chi phí quản lý trung bình.
* **Tác động Chi phí**: Phân tách chi phí rõ ràng cho các môi trường runtime.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Trung bình.
* **Khả năng Đảo ngược**: Có thể đảo ngược kèm di chuyển.
* **Điều kiện tiên quyết**: Thiết lập AWS Organizations.
* **Rủi ro**: Thông tin đăng nhập CI/CD runner dùng chung trải rộng các môi trường.

### Phương án 3: Multi-Account Landing Zone (AWS Organizations Control Tower)
* **Mô tả**: Bốn Tài khoản AWS chuyên trách: Security/Logging, Shared Services (GitLab/Jenkins/ECR), Tài khoản Test, Tài khoản Production.
* **Ưu điểm**: Cô lập bảo mật tối đa; nhật ký kiểm toán tập trung; ranh giới pipeline CI/CD chuyên trách; hóa đơn độc lập.
* **Nhược điểm**: Độ phức tạp thiết lập ban đầu cao hơn; yêu cầu quản trị IAM role xuyên tài khoản.
* **Tác động Bảo mật**: Rất tốt. Không có thông tin đăng nhập IAM dùng chung giữa Test và Prod; nhật ký bảo mật S3 tập trung bất biến.
* **Tác động Sẵn sàng**: Rất tốt. Độc lập hoàn toàn về hạn ngạch và runtime.
* **Tác động Mở rộng**: Rất tốt. Mô hình đơn vị tổ chức (OU) mở rộng linh hoạt.
* **Tác động Vận hành**: Đỏi hỏi năng lực quản lý AWS Control Tower / IAM Identity Center.
* **Tác động Chi phí**: Chi phí cố định AWS cơ sở (ví dụ AWS Config, GuardDuty theo từng tài khoản).
* **Phụ thuộc Nhà cung cấp**: Trung bình (Cấu trúc AWS Control Tower).
* **Độ phức tạp Di chuyển**: Trung bình.
* **Khả năng Đảo ngược**: Dễ dàng đảo ngược / mở rộng.
* **Điều kiện tiên quyết**: Đã bật AWS Organizations.
* **Rủi ro**: Độ phức tạp network peering xuyên tài khoản.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: Một Tài khoản | Phương án 2: Hai Tài khoản | Phương án 3: Multi-Account Landing Zone |
| :--- | :--- | :--- | :--- |
| **Bảo mật & Bán kính Ảnh hưởng** | Yếu | Trung bình | **Mạnh** |
| **Cô lập Độ Sẵn sàng** | Yếu | Mạnh | **Mạnh** |
| **Phân bổ Chi phí** | Yếu | Trung bình | **Mạnh** |
| **Độ phức tạp Vận hành** | Thấp | Trung bình | Trung bình |
| **Khả năng Đảo ngược** | Khó | Có thể đảo ngược | **Dễ dàng Đảo ngược** |

---

## Quyết định Đề xuất
**Phương án 3: Multi-Account Landing Zone** (Security/Logging, Shared Services, Test, Production).

---

## Lý do Lựa chọn
Phương án 3 cung cấp ranh giới bảo mật phòng thủ phân tầng tốt nhất (`SEC-002`), thực thi vết kiểm toán bất biến (`OPS-002`), và đáp ứng yêu cầu phân bổ chi phí FinOps (`CST-002`) mà không làm ảnh hưởng đến độ sẵn sàng.

---

## Hệ quả
* **Tích cực**: Cô lập bán kính ảnh hưởng hoàn toàn; không cạnh tranh giới hạn API; hóa đơn môi trường rõ ràng.
* **Tiêu cực**: Chi phí ban đầu thiết lập IAM role xuyên tài khoản cao hơn.
* **Trách nhiệm Vận hành Mới**: Quản trị AWS Control Tower và quản lý IAM role xuyên tài khoản.
* **Rủi ro Mới**: Cấu hình sai mối quan hệ tin cậy IAM xuyên tài khoản.
* **Hệ quả Chi phí**: Phí cố định nhỏ hàng tháng cho các dịch vụ Security đa tài khoản (GuardDuty, Config).

---

## Bằng chứng Xác minh
* Xem xét cấu hình cơ sở AWS Control Tower và kiểm toán IAM role xuyên tài khoản.

## Điều kiện Nghiệm thu
* Phê duyệt bằng văn bản từ Trưởng nhóm Bảo mật Doanh nghiệp và Kiến trúc sư Trưởng Đám mây.

## Triggers Xem xét lại
* Tái cấu trúc AWS Organization hoặc thay đổi phạm vi tuân thủ quy định.

## Tác động Triển khai
* Cấu trúc đa tài khoản sẽ được cấp phát trong Phase 3 qua mã IaC dạng mô-đun (Terraform).
