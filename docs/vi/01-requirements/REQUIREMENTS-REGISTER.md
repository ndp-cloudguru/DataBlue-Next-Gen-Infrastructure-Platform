# Danh mục Yêu cầu (Requirements Register): Nền tảng AWS Kubernetes DataBlue

---

## 1. Tổng quan

Tài liệu này chứa các yêu cầu đã được chuẩn hóa và có thể truy xuất nguồn gốc cho **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`).

Mỗi yêu cầu được gán một mã định danh duy nhất và được theo dõi xuyên suốt vòng đời dự án.

### Quy ước Mã Định danh Yêu cầu
* `BUS-xxx`: Yêu cầu về Phạm vi Nghiệp vụ & Hệ thống (Business & System Scope)
* `FUN-xxx`: Yêu cầu Chức năng Hạ tầng & Middleware (Functional Infrastructure & Middleware)
* `NFR-xxx`: Yêu cầu Phi Chức năng & Chất lượng Nền tảng (Non-Functional & Platform Quality)
* `SEC-xxx`: Yêu cầu Bảo mật, Quản lý Truy cập & Tuân thủ (Security & Compliance)
* `OPS-xxx`: Yêu cầu Vận hành, Bảo trì & Giám sát (Operations & Monitoring)
* `CST-xxx`: Yêu cầu Ước tính Chi phí & Quản trị FinOps (Cost & FinOps Governance)

---

## 2. Yêu cầu Phạm vi Nghiệp vụ & Hệ thống (`BUS`)

| Mã ID | Mô tả Yêu cầu | Nguồn Yêu cầu | Trạng thái | Mức Ưu tiên | Phương pháp Xác minh | Rủi ro & Phụ thuộc Liên quan |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `BUS-001` | Vận hành khoảng 5–6 hệ thống nghiệp vụ trên nền tảng container Kubernetes cấp doanh nghiệp chạy trên AWS. | Đặc tả Khách hàng | Draft | Bat buộc (Must) | Kiểm toán Kiến trúc & Ánh xạ Namespace | Phụ thuộc vào định nghĩa ranh giới miền microservice. Rủi ro: Phân tách ranh giới chưa rõ ràng. |
| `BUS-002` | Cung cấp năng lực triển khai ứng dụng tự động cho toàn bộ các microservices. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Chạy Kiểm thử Pipeline End-to-End | Phụ thuộc vào tích hợp bộ công cụ CI/CD (`FUN-003`). Rủi ro: Nút thắt quy trình triển khai thủ công. |
| `BUS-003` | Duy trì cô lập môi trường nghiêm ngặt giữa môi trường Test và Production. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm toán Tài khoản AWS & Topo Mạng | Rủi ro: Lỗ hổng bán kính ảnh hưởng khi dùng chung cluster (`ASM-002`). |
| `BUS-004` | Thiết lập khung ước tính chi phí AWS chi tiết cho cả giai đoạn khởi tạo ban đầu và vận hành liên tục. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Xem xét Mô hình FinOps Tham số | Phụ thuộc vào dữ liệu định kích thước tải (`OPEN-001`). Rủi ro: Vượt ngân sách AWS ngoài dự kiến. |

---

## 3. Yêu cầu Chức năng (`FUN`)

| Mã ID | Mô tả Yêu cầu | Nguồn Yêu cầu | Trạng thái | Mức Ưu tiên | Phương pháp Xác minh | Rủi ro & Phụ thuộc Liên quan |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `FUN-001` | Nền tảng phải hỗ trợ khoảng 40 microservices phân tán trên các hệ thống nghiệp vụ. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Mô phỏng Dung lượng EKS Cluster | Phụ thuộc vào dữ liệu chỉ số tài nguyên tải. Rủi ro: Cạnh tranh tài nguyên mật độ node. |
| `FUN-002` | Nền tảng phải tích hợp GitLab để quản lý mã nguồn và trigger pipeline CI. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm thử Tích hợp / Xác minh Webhook | Phụ thuộc vào thiết lập hạ tầng GitLab runner. |
| `FUN-003` | Nền tảng phải tích hợp Jenkins để điều phối build, kiểm thử và đóng gói container. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Xác minh Thực thi Pipeline Job | Rủi ro: Chồng chéo trách nhiệm pipeline với Ansible (`ASM-005`). |
| `FUN-004` | Nền tảng phải tích hợp Ansible để kiểm soát sai lệch cấu hình hạ tầng và tự động hóa triển khai. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Chạy Thử Playbook / Kiểm toán | Phụ thuộc vào kiểm soát truy cập thực thi SSH/API. |
| `FUN-005` | Nền tảng phải cung cấp dịch vụ cơ sở dữ liệu MySQL sẵn sàng cao cho lưu trữ dữ liệu quan hệ. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm thử Failover & Nhân bản Dữ liệu | Phụ thuộc vào quyết định đánh đổi Managed RDS vs Operator trên EKS (`OPEN-002`). |
| `FUN-006` | Nền tảng phải cung cấp dịch vụ message broker RabbitMQ cho luồng sự kiện bất đồng bộ. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Mô phỏng Failover Hàng chờ Tin nhắn | Phụ thuộc vào chính sách lưu trữ trạng thái cluster. |
| `FUN-007` | Nền tảng phải cung cấp dịch vụ cơ sở dữ liệu tài liệu MongoDB cho lưu trữ phi cấu trúc. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm thử Failover Replica Set | Rủi ro: Chi phí lưu trữ IOPS cao trên AWS EBS. |
| `FUN-008` | Nền tảng phải cung cấp bộ nhớ in-memory Redis cho caching và quản lý session tạm thời. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Benchmark & Failover Cluster Cache | Phụ thuộc vào đánh giá ElastiCache vs Redis Operator trên EKS (`OPEN-002`). |
| `FUN-009` | Nền tảng phải cung cấp Nacos cho đăng ký, phát hiện dịch vụ và cấu hình động cho microservices. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm thử Đăng ký & Cập nhật Cấu hình | Phụ thuộc vào phân giải DNS cluster xuyên namespace. |

---

## 4. Yêu cầu Phi Chức năng (`NFR`)

| Mã ID | Mô tả Yêu cầu | Nguồn Yêu cầu | Trạng thái | Mức Ưu tiên | Phương pháp Xác minh | Rủi ro & Phụ thuộc Liên quan |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `NFR-001` | Hạ tầng cốt lõi và control plane của nền tảng phải được thiết kế sẵn sàng cao (Multi-AZ). | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Mô phỏng Sự cố AZ / Chaos Test | Phụ thuộc vào triển khai Multi-AZ trên AWS. Rủi ro: Chi phí truyền dữ liệu xuyên AZ. |
| `NFR-002` | Hạ tầng phải hỗ trợ Mở rộng Linh hoạt cho microservices (cấp Pod) và node tính toán (cấp Node). | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm thử Tạo Tải & HPA/Karpenter | Rủi ro: Độ trễ cấp phát node mới chậm khi đột biến lưu lượng. |
| `NFR-003` | Nền tảng phải tích hợp cơ chế Khôi phục Thảm họa (DR) với chỉ số RTO và RPO rõ ràng. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Mô phỏng Failover DR | Phụ thuộc vào chỉ số RTO/RPO từ khách hàng (`OPEN-004`). |
| `NFR-004` | Các hệ thống cơ sở dữ liệu (MySQL, MongoDB) phải hỗ trợ mở rộng tách biệt (đọc/ghi, sharding). | Quản trị Kiến trúc | Draft | Nên (Should) | Kiểm thử Tải DB & Read-Replica | Phụ thuộc vào đánh giá kiến trúc DB (`NFR-DB-SCALING`). |

---

## 5. Yêu cầu Bảo mật & Quản lý Truy cập (`SEC`)

| Mã ID | Mô tả Yêu cầu | Nguồn Yêu cầu | Trạng thái | Mức Ưu tiên | Phương pháp Xác minh | Rủi ro & Phụ thuộc Liên quan |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `SEC-001` | Nền tảng phải cung cấp quản lý tài khoản và phân quyền truy cập tập trung theo nguyên tắc đặc quyền tối thiểu (IAM & RBAC). | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm toán Chính sách Bảo mật IAM & Pen Test | Phụ thuộc vào tích hợp AWS IAM & Kubernetes RBAC. |
| `SEC-002` | Tải công việc Test và Production phải được phân tách logic và vật lý ở cấp độ Tài khoản AWS. | Quản trị Kiến trúc | Draft | Bắt buộc (Must) | Kiểm toán AWS Organizations & VPC Peering | Rủi ro: Lây nhiễm bán径 ảnh hưởng bảo mật nếu dùng chung. |
| `SEC-003` | Dữ liệu lưu trữ (at rest) và dữ liệu truyền tải (in transit) trên tất cả middleware phải được mã hóa qua AWS KMS và TLS 1.3. | Tuân thủ Bảo mật | Draft | Bắt buộc (Must) | Quét Lỗ hổng & Mã hóa Tự động | Phụ thuộc vào thiết lập chính sách quản lý AWS KMS Key. |

---

## 6. Yêu cầu Vận hành & Giám sát (`OPS`)

| Mã ID | Mô tả Yêu cầu | Nguồn Yêu cầu | Trạng thái | Mức Ưu tiên | Phương pháp Xác minh | Rủi ro & Phụ thuộc Liên quan |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `OPS-001` | Nền tảng phải cung cấp giám sát máy chủ và dịch vụ toàn diện cho các node, pod và middleware. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Bơm Metric Giả lập & Kiểm tra Dashboard | Phụ thuộc vào thiết lập Prometheus/Grafana hoặc AWS CloudWatch. |
| `OPS-002` | Gom nhật ký tập trung phải ghi lại log ứng dụng, log kiểm toán và log hệ thống với thời gian lưu trữ cấu hình được. | Cơ sở Vận hành | Draft | Bắt buộc (Must) | Kiểm toán Tìm kiếm Log & Chính sách Lưu trữ | Rủi ro: Chi phí lưu trữ nạp log cao. |

---

## 7. Yêu cầu Quản lý Chi phí (`CST`)

| Mã ID | Mô tả Yêu cầu | Nguồn Yêu cầu | Trạng thái | Mức Ưu tiên | Phương pháp Xác minh | Rủi ro & Phụ thuộc Liên quan |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CST-001` | Cung cấp mô hình ước tính chi phí AWS chi tiết bao gồm tính toán cơ sở, lưu trữ, dữ liệu ra mạng và chi tiêu middleware. | Đặc tả Khách hàng | Draft | Bắt buộc (Must) | Kiểm toán Mô hình FinOps & So sánh Chi phí | Phụ thuộc vào thiết lập mô hình tính toán chi phí tham số. |
| `CST-002` | Triển khai thẻ (tag) quản trị chi phí đám mây tự động trên 100% tài nguyên AWS được cấp phát. | Quản trị FinOps | Draft | Bắt buộc (Must) | Kiểm toán Tag trên AWS Cost Explorer | Rủi ro: Tài nguyên không gán tag gây ra điểm mù phân bổ chi phí. |
