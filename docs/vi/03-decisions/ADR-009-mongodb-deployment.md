# ADR-009 — Chiến lược Triển khai MongoDB (MongoDB Deployment Strategy)

## Metadata
* **Trạng thái**: `Deferred` (Tạm hoãn)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Dữ liệu, Trưởng nhóm Bảo mật Đám mây
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Trưởng nhóm Phát triển Ứng dụng
* **Yêu cầu Liên quan**: [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-DAT-001` (Bất tương thích wire-protocol Amazon DocumentDB), `RSK-OPS-001` (Độ phức tạp vận hành NoSQL self-hosted)
* **Giả định Liên quan**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 3, Mục 6
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `FUN-007` bắt buộc có các dịch vụ cơ sở dữ liệu tài liệu MongoDB cho lưu trữ dữ liệu phi cấu trúc. Chúng ta phải đánh giá các chiến lược triển khai: MongoDB Operator trên EKS, MongoDB Atlas trên AWS, Amazon DocumentDB, hay một cluster EC2 MongoDB chuyên trách. **Quan trọng là Amazon DocumentDB không tương thích wire-protocol 100% với MongoDB**, thiếu hỗ trợ cho các aggregation pipeline cụ thể, change stream operators và các loại index đặc thù.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Tương thích Wire-Protocol**: Tương thích 100% với các truy vấn driver MongoDB của ứng dụng và các aggregation pipeline (`FUN-007`).
2. **Sẵn sàng Cao Replica Set**: Failover replica set primary/secondary Multi-AZ (`NFR-001`).
3. **Chi phí Vận hành**: Sao lưu tự động, mở rộng lưu trữ và khôi phục replica set (`NFR-003`).
4. **Bản quyền & TCO**: Tuân thủ bản quyền Server Side Public License (SSPL) so với chi phí Amazon DocumentDB (`CST-001`).

---

## Các Hạn chế
* Phải hỗ trợ lưu trữ tài liệu cho microservices mà không yêu cầu viết lại mã nguồn ứng dụng.

---

## Các Phương án Đang Đánh giá

### Phương án 1: MongoDB Community / Enterprise Operator trên EKS
* **Mô tả**: Triển khai các replica set MongoDB native trên EKS sử dụng Operator MongoDB Kubernetes chính thức backed bởi lưu trữ EBS `gp3` trên 3 AZs.
* **Ưu điểm**: Tương thích wire-protocol MongoDB xịn 100%; không phụ thuộc cơ sở dữ liệu đám mây độc quyền; kiểm soát hoàn toàn bản quyền SSPL và bộ tính năng.
* **Nhược điểm**: Đội ngũ phải tự quản lý bầu chọn thành viên replica set, mở rộng lưu trữ EBS, tự động hóa sao lưu và bảo trì node.
* **Tác động Bảo mật**: Tốt. Mã hóa TLS, xác thực SCRAM, mã hóa volume KMS.
* **Tác động Sẵn sàng**: Mạnh khi triển khai dạng replica set 3 thành viên trên 3 AZs.
* **Tác động Mở rộng**: Thêm thành viên replica set và mở rộng dung lượng đĩa EBS thủ công.
* **Tác động Vận hành**: Gánh nặng vận hành liên tục lớn cho đội DBA / SRE (`RSK-OPS-001`).
* **Tác động Chi phí**: Hiệu quả chi phí rất cao (tận dụng tính toán node EKS và lưu trữ EBS sẵn có).
* **Phụ thuộc Nhà cung cấp**: Rất Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Có sẵn driver lưu trữ EBS `gp3` và năng lực vận hành DBA.
* **Rủi ro**: `RSK-OPS-001` (Bầu chọn primary replica set không mong muốn khi bảo trì node).

### Phương án 2: MongoDB Atlas trên AWS (Managed SaaS)
* **Mô tả**: Các cluster cơ sở dữ liệu MongoDB Atlas managed hoàn toàn lưu trữ natively trên hạ tầng AWS.
* **Ưu điểm**: Tương thích MongoDB xịn 100% được bảo chứng trực tiếp bởi MongoDB Inc.; mở rộng multi-AZ managed hoàn toàn, sao lưu tự động và vá lỗi bảo mật.
* **Nhược điểm**: Yêu cầu hợp đồng nhà cung cấp SaaS bên thứ ba; độ phức tạp thiết lập VPC peering / AWS PrivateLink.
* **Tác động Bảo mật**: Rất tốt. Cô lập AWS PrivateLink, mã hóa KMS, audit log chi tiết.
* **Tác động Sẵn sàng**: Rất tốt (SLA 99.99%).
* **Tác động Mở rộng**: Tự động mở rộng cluster online rất tốt.
* **Tác động Vận hành**: Gánh nặng vận hành tối thiểu.
* **Tác động Chi phí**: Chi phí dịch vụ SaaS managed cao cấp hàng tháng.
* **Phụ thuộc Nhà cung cấp**: Trung bình (Phụ thuộc công nghệ MongoDB).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Phê duyệt mua sắm SaaS bên thứ ba.
* **Rủi ro**: Phụ thuộc nhà cung cấp SaaS bên thứ ba (`RSK-VND-001`).

### Phương án 3: Amazon DocumentDB (với Tương thích MongoDB)
* **Mô tả**: Dịch vụ cơ sở dữ liệu tài liệu độc quyền của AWS được thiết kế để mô phỏng các API MongoDB 3.6/4.0/5.0.
* **Ưu điểm**: Do AWS managed hoàn toàn; tích hợp với AWS IAM, CloudWatch, và KMS; lưu trữ phân tán multi-AZ.
* **Nhược điểm**: **TƯƠNG THÍCH WIRE-PROTOCOL MONGODB KHÔNG HOÀN HẢO**. Thiếu hỗ trợ cho các giai đoạn aggregation cụ thể (ví dụ giới hạn `$lookup`), tính năng change stream và các loại index đặc thù.
* **Tác động Bảo mật**: Rất tốt. Tích hợp AWS IAM, KMS và CloudWatch native.
* **Tác động Sẵn sàng**: Rất tốt (SLA 99.99%).
* **Tác động Mở rộng**: Mở rộng lưu trữ lên tới 128TB rất tốt.
* **Tác động Vận hành**: Chi phí quản lý tối thiểu.
* **Tác động Chi phí**: Chi tiêu cơ sở dữ liệu managed AWS hàng tháng cao.
* **Phụ thuộc Nhà cung cấp**: Cao (Phụ thuộc engine lưu trữ AWS DocumentDB).
* **Độ phức tạp Di chuyển**: Cao nếu mã nguồn ứng dụng sử dụng cú pháp MongoDB không được hỗ trợ.
* **Khả năng Đảo ngược**: Khó nếu mã nguồn ứng dụng điều chỉnh theo đặc thù của DocumentDB.
* **Điều kiện tiên quyết**: **BẮT BỘC KIỂM TOÁN toàn bộ các truy vấn cơ sở dữ liệu microservice đối chiếu với ma trận tính năng DocumentDB**.
* **Rủi ro**: `RSK-DAT-001` (Lỗi runtime driver ứng dụng do cú pháp MongoDB không được hỗ trợ).

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: MongoDB trên EKS | Phương án 2: MongoDB Atlas | Phương án 3: Amazon DocumentDB |
| :--- | :--- | :--- | :--- |
| **Tương thích Wire MongoDB** | **100% (Native)** | **100% (Native)** | **CHƯA XÁC MINH (< 100%)** |
| **Chi phí Nhân công Vận hành** | Nặng | **Tối thiểu** | **Tối thiểu** |
| **Độc lập Nhà cung cấp** | **Rất Cao** | Trung bình | Thấp (Khóa vào AWS) |
| **Hiệu quả Chi phí (`CST-001`)** | **Cao** | Trung bình | Yếu (Phí AWS Cao) |
| **Khả năng Đảo ngược** | **Dễ dàng Đảo ngược** | Có thể đảo ngược | Khó |

---

## Quyết định Đề xuất
**Quyết định bị Tạm hoãn (Deferred)**.

---

## Lý do Lựa chọn
Quyết định **được tạm hoãn chờ kiểm toán tương thích thực nghiệm các truy vấn MongoDB của ứng dụng đối chiếu với ma trận tính năng Amazon DocumentDB** (`RSK-DAT-001`).

Tuyên bố Amazon DocumentDB có thể thay thế hoàn hảo MongoDB mà không có bằng chứng là bị nghiêm cấm theo quy định quản trị. Nếu các microservice yêu cầu các tính năng MongoDB không được hỗ trợ, Phương án 1 (MongoDB Operator trên EKS) hoặc Phương án 2 (MongoDB Atlas) sẽ được lựa chọn.

---

## Bằng chứng Xác minh Cần thiết trước khi Phê duyệt
1. Quét tương thích tự động các truy vấn/driver microservice đối chiếu với giới hạn hỗ trợ API DocumentDB (`RSK-DAT-001`).
2. Đo đạc dung lượng lưu trữ tài liệu và IOPS của microservice (`OPEN-001`).

## Điều kiện Nghiệm thu
* Hoàn thành kiểm toán tương thích DocumentDB và phê duyệt từ Kiến trúc sư Trưởng Dữ liệu.

## Triggers Xem xét lại
* Phát hiện các aggregation pipeline MongoDB không tương thích trong quá trình review code Phase 1.

## Tác động Triển khai
* Kiến trúc nền tảng phân bổ các subnet database cô lập có khả năng hỗ trợ các EKS pod hoặc các endpoint PrivateLink.
