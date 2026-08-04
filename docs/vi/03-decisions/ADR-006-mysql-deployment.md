# ADR-006 — Chiến lược Triển khai MySQL (MySQL Deployment Strategy)

## Metadata
* **Trạng thái**: `Deferred` (Tạm hoãn)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Dữ liệu, Trưởng nhóm Hạ tầng Đám mây
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Đội ngũ FinOps
* **Yêu cầu Liên quan**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-UNC-001` (Thiếu hồ sơ tải DB), `RSK-OPS-001` (Gánh nặng vận hành DB self-hosted), `RSK-CST-001` (Tăng chi phí DB managed)
* **Giả định Liên quan**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 3, Mục 6
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `FUN-005` quy định các dịch vụ cơ sở dữ liệu quan hệ MySQL sẵn sàng cao cho lưu trữ dữ liệu ứng dụng. Chúng ta phải xác định topo triển khai cho MySQL (Self-Hosted trên EKS vs. Amazon RDS for MySQL vs. Amazon Aurora MySQL). Các chỉ số tải công việc (kích thước DB, IOPS, số lượng kết nối đồng thời, tỷ lệ đọc/ghi) hiện chưa có sẵn (`OPEN-001`).

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Sẵn sàng Cao & Automated Failover**: Nhân bản đồng bộ/bất đồng bộ Multi-AZ với mục tiêu không mất dữ liệu (`NFR-001`).
2. **Gánh nặng Vận hành & Sao lưu**: Vá lỗi tự động, khôi phục point-in-time (PITR), và tự động mở rộng dung lượng lưu trữ (`NFR-003`).
3. **Tổng Chi phí Sở hữu (TCO)**: Đánh giá bản quyền phần mềm, chi phí hạ tầng đám mây và chi phí nhân công DBA vận hành liên tục (`CST-001`).
4. **Phụ thuộc Nhà cung cấp & Động**: Tự do di chuyển trạng thái cơ sở dữ liệu giữa các đám mây hoặc về on-premises.

---

## Các Hạn chế
* Phải hỗ trợ giao thức wire protocol chuẩn MySQL 8.0+.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Self-Hosted MySQL Operator trên EKS (ví dụ: Bitnami / KubeBlocks Operator)
* **Mô tả**: Triển khai các cluster MySQL master-replica bên trong EKS sử dụng Kubernetes Operators backed bởi các EBS persistent volumes (`gp3`).
* **Ưu điểm**: Loại bỏ phí dịch vụ managed cơ sở dữ liệu AWS; toàn quyền truy cập các biến cấu hình MySQL; khả năng linh hoạt chuyển đổi đám mây hoàn hảo.
* **Nhược điểm**: Độ phức tạp vận hành cao; đội ngũ phải tự quản lý failover volume, sửa chữa nhân bản thủ công, vòng đời EBS snapshot và vá lỗi DBA.
* **Tác động Bảo mật**: Trung bình. Gia cố bảo mật và mã hóa EBS volume KMS do đội ngũ quản lý.
* **Tác động Sẵn sàng**: Trung bình. Phụ thuộc độ trễ lập lịch lại pod Kubernetes và độ trễ gắn lại EBS volume (~2-5 phút khi có sự cố AZ).
* **Tác động Mở rộng**: Mở rộng read-replica pod và EBS volume thủ công.
* **Tác động Vận hành**: Gánh nặng chi phí nhân công DBA và SRE liên tục rất lớn (`RSK-OPS-001`).
* **Tác động Chi phí**: Chi phí hạ tầng AWS thấp hơn, nhưng chi phí bảo trì nhân công liên tục cao.
* **Phụ thuộc Nhà cung cấp**: Rất Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Đội ngũ DBA / SRE chuyên trách có chuyên môn về StatefulSet Kubernetes.
* **Rủi ro**: `RSK-OPS-001` (Hỏng volume cơ sở dữ liệu hoặc lỗi nhân bản khi node crash).

### Phương án 2: Amazon RDS for MySQL (Multi-AZ)
* **Mô tả**: Cấp phát các instance Amazon RDS MySQL managed hoàn toàn triển khai trên 2-3 Availability Zones với failover tự động.
* **Ưu điểm**: Giảm 95% công việc vận hành DBA; failover Multi-AZ tự động (< 60 giây); sao lưu tự động hàng ngày và PITR; vá lỗi bảo mật do AWS quản lý.
* **Nhược điểm**: Giá theo giờ instance AWS cao hơn so với tính toán EC2/EKS thuần.
* **Tác động Bảo mật**: Rất tốt. Mã hóa AWS KMS native, xác thực IAM database, cô lập subnet VPC.
* **Tác động Sẵn sàng**: Mạnh. SLA uptime 99.95% cam kết từ AWS.
* **Tác động Mở rộng**: Dễ dàng mở rộng kích thước instance theo chiều dọc và thêm read-replica endpoint.
* **Tác động Vận hành**: Yêu cầu bảo trì vận hành tối thiểu từ đội DevOps.
* **Tác động Chi phí**: Chi tiêu hàng tháng AWS ở mức Trung bình-Cao.
* **Phụ thuộc Nhà cung cấp**: Thấp-Trung bình (Tương thích engine MySQL tiêu chuẩn).
* **Độ phức tạp Di chuyển**: Thấp (Dùng `mysqldump` tiêu chuẩn / AWS DMS).
* **Khả năng Đảo ngược**: Có thể đảo ngược kèm di chuyển.
* **Điều kiện tiên quyết**: Các Subnet VPC Database Cô lập (`SEC-002`).
* **Rủi ro**: `RSK-CST-001` (Tăng chi phí cơ sở dữ liệu managed không kiểm soát nếu không giám sát).

### Phương án 3: Amazon Aurora MySQL-Compatible
* **Mô tả**: Engine cơ sở dữ liệu quan hệ cloud-native độc quyền của AWS cung cấp lưu trữ phân tán được nhân bản 6 hướng trên 3 AZs.
* **Ưu điểm**: Hiệu năng cao (lên tới 5 lần băng thông MySQL tiêu chuẩn); lưu trữ tự động mở rộng lên tới 128TB; khôi phục sự cố gần như tức thì (< 30 giây).
* **Nhược điểm**: Chi phí cơ sở cao hơn đáng kể; tầng lưu trữ độc quyền AWS.
* **Tác động Bảo mật**: Rất tốt.
* **Tác động Sẵn sàng**: Rất tốt (SLA 99.99%).
* **Tác động Mở rộng**: Rất tốt (Read replica nhanh và tự động mở rộng lưu trữ).
* **Tác động Vận hành**: Chi phí quản lý tối thiểu.
* **Tác động Chi phí**: Phương án chi phí cao nhất (cao hơn 20-40% so với RDS tiêu chuẩn).
* **Phụ thuộc Nhà cung cấp**: Cao (Phụ thuộc kiến trúc lưu trữ Aurora).
* **Độ phức tạp Di chuyển**: Trung bình.
* **Khả năng Đảo ngược**: Có thể đảo ngược kèm di chuyển.
* **Điều kiện tiên quyết**: Yêu cầu băng thông ghi cao vượt quá năng lực RDS tiêu chuẩn.
* **Rủi ro**: Phụ thuộc nhà cung cấp đám mây và chi tiêu hàng tháng cao.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: MySQL trên EKS Operator | Phương án 2: Amazon RDS MySQL | Phương án 3: Amazon Aurora MySQL |
| :--- | :--- | :--- | :--- |
| **Sẵn sàng & SLA (`NFR-001`)** | Trung bình | **Mạnh (99.95%)** | **Mạnh (99.99%)** |
| **Chi phí Nhân công Vận hành** | Nặng | **Tối thiểu** | **Tối thiểu** |
| **Trần Hiệu năng** | Trung bình | Trung bình-Cao | **Cao** |
| **Hiệu quả Chi phí (`CST-001`)** | Hạ tầng Thấp / Nhân công Cao | **Cân bằng** | Yếu (Phí AWS Cao) |
| **Phụ thuộc Nhà cung cấp** | **Rất Thấp** | Trung bình | Cao |

---

## Quyết định Đề xuất
**Quyết định bị Tạm hoãn (Deferred)**.

---

## Lý do Lựa chọn
Lựa chọn kiến trúc cuối cùng giữa Amazon RDS for MySQL (Phương án 2) và Self-Hosted MySQL Operator trên EKS (Phương án 1) **không thể đưa ra một cách có cơ sở bảo vệ được nếu thiếu dữ liệu đo đạc tải cơ sở dữ liệu thực nghiệm** (`OPEN-001`).

Lựa chọn Phương án 2 khi chưa định kích thước mang rủi ro vượt ngân sách; lựa chọn Phương án 1 khi thiếu các chỉ số đội ngũ DBA mang rủi ro thất bại vận hành.

---

## Bằng chứng Xác minh Cần thiết trước khi Phê duyệt
1. Kích thước dữ liệu MySQL microservice, giao dịch RPS, tỷ lệ đọc/ghi và yêu cầu connection pool (`OPEN-001`).
2. Năng lực vận hành DBA và phê duyệt SLA ứng cứu sự cố.
3. Xem xét phân bổ ngân sách hàng tháng từ FinOps.

## Điều kiện Nghiệm thu
* Nộp các chỉ số tải cơ sở dữ liệu khách hàng được xác minh và xem xét chính thức từ Hội đồng Kiến trúc.

## Triggers Xem xét lại
* Hoàn thành đo đạc tải công việc trong Phase 1.

## Tác động Triển khai
* Thiết kế kiến trúc duy trì trừu tượng cô lập subnet database trong IaC cho đến khi có phê duyệt quyết định trong Phase 1.
