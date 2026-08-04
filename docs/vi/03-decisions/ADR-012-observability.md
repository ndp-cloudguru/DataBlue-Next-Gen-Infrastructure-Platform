# ADR-012 — Kiến trúc Khả năng Quan sát (Observability Architecture)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kỹ sư Trưởng Vận hành, Kiến trúc sư Đám mây
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Trưởng nhóm DevOps
* **Yêu cầu Liên quan**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-CST-002` (Chi phí lưu trữ log quan sát không kiểm soát), `RSK-OPS-002` (Thiếu các dashboard metric dịch vụ)
* **Giả định Liên quan**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 11
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Các yêu cầu `OPS-001` và `OPS-002` bắt buộc giám sát máy chủ và dịch vụ toàn diện, gom log tập trung, và trực quan hóa metric trên ~40 microservices, các node Kubernetes và các thành phần middleware. Chúng ta phải lựa chọn kiến trúc stack quan sát đồng thời kiểm soát chi phí lưu trữ log AWS (`CST-001`).

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Trực quan hóa Metric & Log Thống nhất**: Các dashboard giao diện tập trung cho các metric container, CPU/RAM node, và log ứng dụng (`OPS-001`).
2. **Đồng bộ Kubernetes & Cloud Native**: Tương thích thu thập metric Prometheus trên các microservice và Nacos (`OPS-001`).
3. **Quản trị Chi phí Lưu trữ Log**: Kiểm soát chi phí nạp log cao và lưu trữ dài hạn cho CloudWatch logs (`CST-001`, `OPS-002`).

---

## Các Hạn chế
* Phải hỗ trợ giám sát tập trung cho cả hai môi trường Test và Production.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Stack Mã nguồn mở Self-Hosted (Prometheus + Grafana + Loki trên EKS)
* **Mô tả**: Triển khai Prometheus Operator, Grafana và Loki log aggregator bên trong EKS sử dụng EBS persistent volumes.
* **Ưu điểm**: Linh hoạt mã nguồn mở hoàn toàn; không tốn phí nạp theo từng metric của AWS; hệ sinh thái dashboard Grafana phong phú.
* **Nhược điểm**: Tiêu tốn RAM worker node và lưu trữ EBS cao; đội ngũ phải tự quản lý thời gian lưu trữ Prometheus TSDB và mở rộng Loki index.
* **Tác động Bảo mật**: Tốt. Thực thi RBAC và network policies.
* **Tác động Sẵn sàng**: Trung bình. Sự cố node lưu trữ có thể gây ra khoảng trống metric tạm thời.
* **Tác động Mở rộng**: Yêu cầu tinh chỉnh lưu trữ TSDB thủ công.
* **Tác động Vận hành**: Đội ngũ SRE phải quản lý hạ tầng cluster quan sát.
* **Tác động Chi phí**: Phí dịch vụ AWS thấp, nhưng tiêu tốn tính toán/lưu trữ node cao hơn.
* **Phụ thuộc Nhà cung cấp**: Rất Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Dung lượng lưu trữ EKS.
* **Rủi ro**: Lỗi crash loop bộ nhớ Prometheus TSDB khi có bùng nổ độ đa dạng metric (cardinality explosion).

### Phương án 2: AWS Managed Service for Prometheus (AMP) + Managed Grafana (AMG)
* **Mô tả**: Sử dụng dịch vụ nạp metric Prometheus managed hoàn toàn của AWS và workspace AWS Managed Grafana.
* **Ưu điểm**: Zero quản lý máy chủ; mở rộng lưu trữ metric vô hạn; SLA uptime 99.9%.
* **Nhược điểm**: Giá nạp log tăng tuyến tính theo số mẫu metric ($0.90 per million samples); chi phí hàng tháng cao cho ~40 microservices với độ đa dạng metric cao.
* **Tác động Bảo mật**: Rất tốt. Tích hợp AWS IAM SSO native.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Gánh nặng vận hành tối thiểu.
* **Tác động Chi phí**: Chi tiêu AWS hàng tháng cao cho các metric độ đa dạng cao (`RSK-CST-002`).
* **Phụ thuộc Nhà cung cấp**: Trung bình.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: AWS SSO / IAM Identity Center.
* **Rủi ro**: `RSK-CST-002` (Đột biến hóa đơn AWS hàng tháng ngoài dự kiến từ các metric độ đa dạng cao).

### Phương án 3: Giải pháp Trọng tâm AWS CloudWatch Thuần túy
* **Mô tả**: Sử dụng CloudWatch Container Insights cho các metric và CloudWatch Logs cho toàn bộ log ứng dụng.
* **Ưu điểm**: Tích hợp AWS sẵn có; 0 yêu cầu triển khai helm chart.
* **Nhược điểm**: Cú pháp truy vấn log CloudWatch độc quyền; phí nạp log đắt đỏ ($0.50/GB) và giá dữ liệu metric cao; độ linh hoạt dashboard cho lập trình viên kém hơn Grafana.
* **Tác động Bảo mật**: Rất tốt.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Quản lý tối thiểu.
* **Tác động Chi phí**: Phí nạp log hàng tháng rất cao.
* **Phụ thuộc Nhà cung cấp**: Cao (Định dạng độc quyền AWS CloudWatch).
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: Leo thang chi phí cực lớn khi thể tích log cao.

### Phương án 4: Kiến trúc Lai (Prometheus/Grafana + Fluent Bit tới OpenSearch & S3)
* **Mô tả**: Một kiến trúc lai cân bằng:
  1. **Prometheus Operator + Grafana trên EKS**: Thu thập và trực quan hóa metric cục bộ tốc độ cao cho các dashboard vận hành (`OPS-001`).
  2. **Fluent Bit DaemonSet**: Bộ chuyển tiếp log mỏng nhẹ cài đặt trên tất cả các node.
  3. **Amazon OpenSearch Service**: Tìm kiếm và đánh chỉ mục log thời gian thực trong 7-14 ngày (`OPS-002`).
  4. **Lưu trữ Vòng đời Amazon S3**: Khái niệm xuất log thô tự động sang S3 Standard / Glacier để lưu trữ tuân thủ dài hạn với chi phí tối thiểu (`CST-001`).
* **Ưu điểm**: Mang lại độ linh hoạt dashboard Grafana vượt trội; kiểm soát chi phí log nhờ lưu trữ S3; giải phóng đánh chỉ mục log khỏi RAM node EKS sang OpenSearch.
* **Nhược điểm**: Yêu cầu cấu hình các quy tắc định tuyến Fluent Bit và chính sách vòng đời S3.
* **Tác động Bảo mật**: Rất tốt. Cô lập OpenSearch VPC, mã hóa KMS.
* **Tác động Sẵn sàng**: Cao. Miền sự cố logging cô lập.
* **Tác động Mở rộng**: Cao. Tự động mở rộng OpenSearch cluster.
* **Tác động Vận hành**: Quản lý các config map Fluent Bit ở mức trung bình.
* **Tác động Chi phí**: Hiệu quả chi phí rất cao (vòng đời S3 tiết kiệm 80% lưu trữ log dài hạn).
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Thiết lập Amazon OpenSearch cluster.
* **Rủi ro**: `RSK-CST-002` (Log debug không lọc gây cạn kiệt dung lượng lưu trữ OpenSearch cluster).

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: OSS Thuần | Phương án 2: AWS AMP/AMG | Phương án 3: CloudWatch | Phương án 4: Giải pháp Lai |
| :--- | :--- | :--- | :--- | :--- |
| **Linh hoạt Metric (`OPS-001`)** | **Mạnh** | **Mạnh** | Yếu | **Mạnh** |
| **Kiểm soát Chi phí Log (`CST-001`)** | Trung bình | Trung bình | Yếu | **Mạnh (Vòng đời S3)** |
| **Chi phí Nhân công Vận hành** | Nặng | **Tối thiểu** | **Tối thiểu** | Trung bình |
| **Độc lập Nhà cung cấp** | **Rất Cao** | Trung bình | Thấp | **Cao** |
| **Khả năng Đảo ngược** | **Dễ dàng Đảo ngược** | Có thể đảo ngược | Khó | **Dễ dàng Đảo ngược** |

---

## Quyết định Đề xuất
**Phương án 4: Kiến trúc Lai** (Prometheus/Grafana trên EKS + Fluent Bit tới Amazon OpenSearch & S3).

---

## Lý do Lựa chọn
Phương án 4 mang lại trải nghiệm dashboard Prometheus/Grafana chuẩn công nghiệp (`OPS-001`), cung cấp tìm kiếm log thời gian thực qua OpenSearch (`OPS-002`), và kiểm soát nghiêm ngặt chi phí FinOps bằng cách tận dụng các quy tắc vòng đời S3 Glacier cho lưu trữ log dài hạn (`CST-001`).

---

## Hệ quả
* **Tích cực**: Tuân thủ 100% các yêu cầu; dashboard metric thời gian thực; tiết kiệm 80% chi phí lưu trữ log dài hạn qua S3 Glacier.
* **Tiêu cực**: Yêu cầu duy trì cấu hình Fluent Bit DaemonSet.
* **Trách nhiệm Vận hành Mới**: Quản lý xoay vòng chỉ mục OpenSearch cluster và các chính sách vòng đời S3.
* **Rủi ro Mới**: `RSK-CST-002` (Thể tích log đột biến nếu log debug ứng dụng bị bật ở Prod).
* **Hệ quả Chi phí**: Giá instance OpenSearch dự đoán được + chi phí lưu trữ S3 thấp.

---

## Bằng chứng Xác minh
* Benchmark chuyển tiếp log Fluent Bit và xác minh xuất log vòng đời S3.

## Điều kiện Nghiệm thu
* Phê duyệt từ Trưởng nhóm Vận hành và Đội ngũ FinOps.

## Triggers Xem xét lại
* Thể tích nạp log vượt quá 500 GB/ngày.

## Tác động Triển khai
* Manifest Prometheus Operator và Fluent Bit Helm chart được triển khai trong Phase 3.
