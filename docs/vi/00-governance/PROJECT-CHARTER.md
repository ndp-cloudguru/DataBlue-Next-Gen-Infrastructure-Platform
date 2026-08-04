# Điều lệ Dự án: Nền tảng AWS Kubernetes DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Mục tiêu Nghiệp vụ

Mục tiêu chính của sáng kiến **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`) là thiết kế, mô hình hóa và thiết lập một hạ tầng cơ sở điện toán đám mây cấp doanh nghiệp, có khả năng sẵn sàng cao, mở rộng linh hoạt và bảo mật trên AWS.

Nền tảng sẽ cung cấp một môi trường lưu trữ container tập trung, tự động hóa cho khoảng 40 microservices thuộc 5–6 hệ thống nghiệp vụ cốt lõi, được hỗ trợ bởi các dịch vụ middleware doanh nghiệp (MySQL, RabbitMQ, MongoDB, Redis, Nacos) và bộ công cụ CI/CD thống nhất (GitLab, Jenkins, Ansible).

Các mục tiêu nghiệp vụ chính bao gồm:
* **Sự Linh hoạt trong Nghiệp vụ (Business Agility)**: Đẩy nhanh tốc độ bàn giao tính năng trên các hệ thống nghiệp vụ thông qua các pipeline triển khai ứng dụng tự động.
* **Độ Bền vững Vận hành (Operational Resilience)**: Đảm bảo không có điểm lỗi đơn lẻ (SPOF) trong môi trường Production với khả năng sẵn sàng cao (HA) và khôi phục thảm họa (DR).
* **Khả năng Dự đoán Chi phí (Cost Predictability)**: Thiết lập mô hình quản trị và ước tính chi phí FinOps minh bạch để ngăn ngừa tình trạng vượt ngân sách AWS.
* **Quản trị & Bảo mật (Governance & Security)**: Thực thi cô lập môi trường nghiêm ngặt (Test vs Production) và quản lý quyền truy cập chi tiết.

---

## 2. Phạm vi Đã Xác định

* **Cơ sở Định kích thước Ứng dụng**: Cấu trúc các yêu cầu cho ~40 microservices trên 5-6 hệ thống nghiệp vụ.
* **Kiến trúc Đa Môi trường**: Cô lập hoàn toàn môi trường Test và Production ở cả cấp độ tài khoản AWS và ranh giới cluster EKS.
* **Tích hợp CI/CD Tự động**: Định nghĩa ranh giới điều phối triển khai giữa GitLab, Jenkins và Ansible.
* **Kiến trúc Middleware Lưu trữ Trạng thái**: Đánh giá kiến trúc MySQL, RabbitMQ, MongoDB, Redis và Nacos (Dịch vụ AWS Managed vs Operator trên EKS).
* **Mở rộng Đa tầng Linh hoạt**: Thiết kế cơ chế tự động mở rộng Pod (HPA), mở rộng Node (Karpenter/Cluster Autoscaler), và mở rộng Cơ sở Dữ liệu.
* **Khả năng Quan sát & Bảo mật**: Giám sát, ghi log, tracing, IAM RBAC và quản lý secret toàn diện dựa trên AWS-native và mã nguồn mở.
* **Ước tính Chi phí Tham số**: Mô hình hóa chi phí FinOps cơ sở trên các tầng tính toán, lưu trữ, truyền dữ liệu và middleware.

---

## 3. Ngoài Phạm vi Dự án

* **Tái cấu trúc Mã nguồn Ứng dụng**: Sửa đổi mã nguồn ứng dụng nghiệp vụ hoặc viết logic nghiệp vụ cấp ứng dụng.
* **Triển khai Hạ tầng Ngay lập tức**: Triển khai AWS VPC, EKS cluster hoặc cơ sở dữ liệu thực tế trong Phase 0 / Phase 1.
* **Thực thi Script CI/CD**: Chạy các pipeline triển khai Jenkins/Ansible trong giai đoạn thiết kế kiến trúc.
* **Di chuyển Hạ tầng Legacy Self-Hosted**: Thực thi di chuyển máy chủ vật lý hoặc di chuyển dữ liệu cơ sở dữ liệu.

---

## 4. Ma trận Các Bên Liên quan (Stakeholder Matrix)

| Vai trò Báo cáo | Trách nhiệm Quản lý | Trọng tâm Quản lý Chính |
| :--- | :--- | :--- |
| **Trưởng nhóm Kiến trúc Doanh nghiệp (Enterprise Architecture Lead)** | Quản trị kỹ thuật tổng thể, phê duyệt ADR, thực thi chuẩn mực nền tảng | Tính đồng nhất hệ thống, tránh nợ kỹ thuật, tuân thủ bảo mật |
| **Trưởng nhóm Đám mây / DevOps (DevOps Lead)** | Thiết kế hạ tầng, kiến trúc IaC, tích hợp pipeline CI/CD | Khả năng duy trì vận hành, tự động hóa triển khai, ổn định nền tảng |
| **Chủ sở hữu Sản phẩm Nghiệp vụ (Product Owners)** | Định nghĩa SLA hệ thống nghiệp vụ, kỳ vọng lưu lượng, tần suất release | Thời gian hoạt động (Uptime), tốc độ triển khai, giảm thiểu gián đoạn |
| **An toàn Thông tin (SecOps)** | Thực thi quyền IAM, cô lập mạng, giám sát tuân thủ bảo mật | Truy cập đặc quyền tối thiểu, mã hóa dữ liệu, nhật ký kiểm toán, kiểm soát rủi ro |
| **Đội ngũ Tài chính / FinOps** | Xem xét mô hình chi phí, phê duyệt trần ngân sách, theo dõi chi tiêu đám mây | Ước tính chi phí AWS chi tiết, tối ưu hóa chi phí, chính sách rightsizing |

---

## 5. Các Nguyên tắc Bàn giao

1. **Quản trị Hướng Kiến trúc**: Các đặc tả, danh mục đăng ký và ADR phải được hoàn thành và phê duyệt trước khi viết bất kỳ mã nguồn IaC nào.
2. **Ưu tiên Quyết định Có thể Đảo ngược**: Ưu tiên các trừu tượng kiến trúc linh hoạt, mô-đun hóa trong khi các chỉ số tải công việc của khách hàng chưa hoàn chỉnh.
3. **Phân tách Môi trường Nghiêm ngặt**: Môi trường Test và Production không bao giờ được chia sẻ chung một cluster Kubernetes trừ khi được tài liệu hóa và ủy quyền qua ngoại lệ chính thức.
4. **Định nghĩa Độ Bền vững Độc lập**: Tách biệt rõ ràng Khả năng Sẵn sàng Cao (HA), Sao lưu (Backup) và Khôi phục Thảm họa (DR) trong thiết kế và SLA mục tiêu.
5. **Sẵn sàng Dựa trên Bằng chứng**: Không có hệ thống hoặc hệ thống con nào được tuyên bố sẵn sàng cho Production nếu chưa qua kiểm thử benchmark thực nghiệm và xác minh nghiệm thu bằng văn bản.

---

## 6. Chỉ số Đo lường Thành công (KPIs)

* **Chỉ số Truy xuất Nguồn gốc**: 100% các quyết định kiến trúc và module IaC có thể truy xuất nguồn gốc về các yêu cầu đã đăng ký (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`).
* **Tính Hoàn chỉnh của ADR**: Bao phủ ADR chính thức cho tất cả các đánh đổi cốt lõi (topological EKS, Managed vs Self-Hosted middleware, ranh giới CI/CD).
* **Ranh giới Ảnh hưởng Môi trường**: 0 phụ thuộc hạ tầng dùng chung giữa môi trường Test và Production.
* **Độ Lệch Dự đoán Chi phí**: Chi tiêu AWS thực tế nằm trong khoảng ±15% so với mô hình chi phí tham số cơ sở khi có đủ dữ liệu đo đạc tải.
* **Tuân thủ Độ Sẵn sàng**: Kiến trúc nền tảng Production được xác minh hỗ trợ Multi-AZ High Availability (Mục tiêu SLA ≥99.9% khi đã định kích thước tải).
