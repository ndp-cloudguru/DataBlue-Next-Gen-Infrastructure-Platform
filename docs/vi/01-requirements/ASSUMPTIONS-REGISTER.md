# Nhật ký Giả định (Assumptions Register): Nền tảng AWS Kubernetes DataBlue

---

## 1. Tổng quan

Tài liệu này ghi lại các giả định kỹ thuật và kiến trúc được đưa ra cho **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`) do thiếu hoặc chưa hoàn chỉnh dữ liệu đo đạc tải công việc của khách hàng trong Phase 0.

Mỗi giả định đều được theo dõi, gán người chịu trách nhiệm và phương pháp xác minh để đảm bảo được xác nhận hệ thống trước khi sinh mã IaC trong Phase 3.

---

## 2. Nhật ký Giả định Chuẩn hóa

### `ASM-001`: Độ Sẵn sàng Container của Microservices
* **Giả định**: Toàn bộ ~40 microservices thuộc 5–6 hệ thống nghiệp vụ đã được container hóa (tuân thủ Docker/OCI), là ứng dụng không lưu trạng thái (stateless) và hỗ trợ cấu hình ứng dụng chuẩn 12-Factor qua biến môi trường hoặc Nacos.
* **Lý do**: Khách hàng chỉ định một nền tảng chạy trên Kubernetes vận hành 40 microservices.
* **Tác động nếu Sai**: Các thành phần ứng dụng có lưu trạng thái (stateful) sẽ yêu cầu cấu hình persistent volume chuyên dụng, StatefulSets hoặc phải tái cấu trúc lại mã nguồn.
* **Phương pháp Xác minh**: Kiểm toán độ sẵn sàng container trong codebase và kiểm tra Dockerfile trên các repository của microservice.
* **Người chịu trách nhiệm**: Trưởng nhóm Phát triển Ứng dụng / Kiến trúc sư Trưởng
* **Trạng thái**: Đang mở / Chờ xác minh

---

### `ASM-002`: Phân tách Môi trường ở Cấp độ Tài khoản AWS
* **Giả định**: Môi trường Test và Production sẽ được lưu trữ trong các tài khoản AWS riêng biệt thuộc cấu trúc AWS Organization cơ sở (ví dụ: `DataBlue-Test-Account` và `DataBlue-Prod-Account`).
* **Lý do**: Quản trị bảo mật đám mây tiêu chuẩn nghiêm cấm việc đặt chung Test và Prod trong cùng một EKS cluster qua các namespace nếu không có ngoại lệ phê duyệt từ cấp lãnh đạo.
* **Tác động nếu Sai**: Đặt chung Test/Prod trong một cluster sẽ tạo ra lỗ hổng rủi ro bán kính ảnh hưởng nghiêm trọng, nhiễu hiệu năng do chung tài nguyên (noisy-neighbor) và nguy cơ vi phạm tuân thủ bảo mật dữ liệu.
* **Phương pháp Xác minh**: Phê duyệt Kiến trúc Bảo mật và xác nhận cấu trúc Tài khoản AWS.
* **Người chịu trách nhiệm**: Trưởng nhóm Bảo mật Đám mây / Kiến trúc sư Doanh nghiệp
* **Trạng thái**: Baseline Đề xuất / Chờ Phê duyệt

---

### `ASM-003`: Topo Sẵn sàng Cao Multi-AZ cho EKS
* **Giả định**: Các worker node EKS và middleware lưu trạng thái sẽ trải rộng trên ít nhất 3 Availability Zones (AZs) trong một Region AWS mục tiêu (ví dụ: `us-east-1` hoặc `ap-southeast-1`).
* **Lý do**: Topo Multi-AZ là bắt buộc để đáp ứng yêu cầu Khả năng Sẵn sàng Cao (HA) (`NFR-001`).
* **Tác động nếu Sai**: Triển khai Single-AZ hoặc 2-AZ mang rủi ro gián đoạn cao hơn cho control plane / worker node khi có sự cố vùng AWS.
* **Phương pháp Xác minh**: Xác minh hạn ngạch AZ của AWS theo vùng và xem xét kế hoạch topo subnet VPC.
* **Người chịu trách nhiệm**: Kiến trúc sư Trưởng Hạ tầng
* **Trạng thái**: Bản thảo / Đang Đánh giá

---

### `ASM-004`: Đánh giá Chiến lược Kiến trúc Middleware
* **Giả định**: Cả hai phương án AWS Managed Services (RDS MySQL, ElastiCache Redis, MSK/DocumentDB) và Self-Hosted Middleware Operators trên EKS sẽ được đánh giá qua quy trình ADR chính thức trước khi chốt kiến trúc dịch vụ lưu trạng thái.
* **Lý do**: Khách hàng yêu cầu MySQL, RabbitMQ, MongoDB, Redis và Nacos nhưng chưa chỉ định ưu tiên AWS Managed hay Self-Hosted trên K8s.
* **Tác động nếu Sai**: Vội vàng chốt Self-Hosted làm tăng gánh nặng vận hành; chốt hoàn toàn AWS Managed làm tăng phụ thuộc nhà cung cấp (vendor lock-in) và chi phí đám mây.
* **Phương pháp Xác minh**: Ma trận đánh giá đánh đổi ADR Phase 1 (`OPEN-002`).
* **Người chịu trách nhiệm**: Kiến trúc sư Dữ liệu / Trưởng nhóm Hạ tầng Đám mây
* **Trạng thái**: Đang mở / Chờ Đánh đổi

---

### `ASM-005`: Phân định Trách nhiệm Pipeline CI/CD
* **Giả định**: GitLab xử lý trigger mã nguồn; Jenkins điều phối build container, quét lỗ hổng ảnh và push vào AWS ECR; Ansible thực thi quản lý cấu hình và câu lệnh triển khai ứng dụng tới môi trường mục tiêu.
* **Lý do**: Yêu cầu khách hàng bao gồm đồng thời cả GitLab, Jenkins và Ansible.
* **Tác động nếu Sai**: Chồng chéo pipeline, lặp lại các bước build, sai lệch cấu hình và triển khai release không đồng bộ.
* **Phương pháp Xác minh**: Phê duyệt tài liệu Đặc tả Kiến trúc Luồng công việc CI/CD.
* **Người chịu trách nhiệm**: Kỹ sư Trưởng DevOps
* **Trạng thái**: Đề xuất / Chờ Xem xét

---

### `ASM-006`: Mô hình Phân bổ Tài nguyên Mặc định Ban đầu
* **Giả định**: Cho đến khi có chỉ số dịch vụ thực tế, các yêu cầu tài nguyên microservice cơ sở sẽ được mô hình hóa tạm thời theo các cấp: `Small` (0.25 vCPU, 0.5 GB RAM), `Medium` (0.5 vCPU, 1.0 GB RAM), và `Large` (1.0 vCPU, 2.0 GB RAM) theo tỷ lệ 50/35/15.
* **Lý do**: Dữ liệu định kích thước hiện chưa được cung cấp từ khách hàng (`OPEN-001`).
* **Tác động nếu Sai**: Mô hình ước tính chi phí sẽ cần tính toán lại khi có chỉ số vCPU/RAM thực nghiệm.
* **Phương pháp Xác minh**: Đo đạc benchmark trong môi trường Test trong Phase 3.
* **Người chịu trách nhiệm**: Chuyên viên Phân tích FinOps / Kiến trúc sư Đám mây
* **Trạng thái**: Tạm thời / Placeholder Kích thước

---

### `ASM-007`: Truyền Dữ liệu Vùng & Thời gian Lưu trữ Dữ liệu
* **Giả định**: Thời gian lưu trữ log là 30 ngày trong CloudWatch/OpenSearch với vòng đời lưu trữ S3 Glacier; sao lưu cơ sở dữ liệu tuân theo lưu trữ snapshot hàng ngày 7 ngày.
* **Lý do**: Chỉ số phi chức năng của khách hàng hiện bỏ qua các cửa sổ lưu trữ tuân thủ cụ thể.
* **Tác động nếu Sai**: Yêu cầu lưu trữ kéo dài (ví dụ 365 ngày cho PCI-DSS/HIPAA) sẽ làm tăng đáng kể chi phí lưu trữ AWS.
* **Phương pháp Xác minh**: Phê duyệt yêu cầu Pháp lý & Tuân thủ từ phía Khách hàng.
* **Người chịu trách nhiệm**: Trưởng nhóm Tuân thủ / Kỹ sư Vận hành
* **Trạng thái**: Đang mở / Chờ Xác nhận
