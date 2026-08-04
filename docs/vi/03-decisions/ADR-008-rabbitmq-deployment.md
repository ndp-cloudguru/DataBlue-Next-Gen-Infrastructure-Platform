# ADR-008 — Chiến lược Triển khai RabbitMQ (RabbitMQ Deployment Strategy)

## Metadata
* **Trạng thái**: `Deferred` (Tạm hoãn)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Dữ liệu, Trưởng nhóm Hạ tầng Đám mây
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Trưởng nhóm DevOps
* **Yêu cầu Liên quan**: [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-UNC-001` (Thiếu dữ liệu thể tích tin nhắn), `RSK-OPS-001` (Độ phức tạp lưu trạng thái của message broker)
* **Giả định Liên quan**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 3, Mục 6
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `FUN-006` quy định các dịch vụ message broker RabbitMQ cho luồng sự kiện bất đồng bộ và truyền tin nhắn inter-service trên các hệ thống nghiệp vụ. Chúng ta phải xác định triển khai RabbitMQ qua K8s Cluster Operator chính thức trên EKS, Amazon MQ for RabbitMQ, hay một cluster EC2 chuyên trách. Băng thông tin nhắn (msg/sec), tính bền vững hàng chờ và chỉ số dung lượng payload hiện chưa được xác nhận (`OPEN-001`).

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Độ Bền vững Hàng chờ Quorum**: Mirroring tin nhắn Multi-AZ và độ bền hàng chờ lưu trữ liên tục (`NFR-001`).
2. **Băng thông Tin nhắn & Độ trễ**: Chuyển giao tin nhắn AMQP 0-9-1 / MQTT độ trễ thấp (`FUN-006`).
3. **Chi phí Vận hành**: Quản lý nâng cấp Erlang VM, phân tách mạng cluster (khắc phục split-brain), và sử dụng đĩa hàng chờ.
4. **Kiến trúc Chi phí**: So sánh chi phí broker managed Amazon MQ với chi phí tính toán EKS/lưu trữ EBS (`CST-001`).

---

## Các Hạn chế
* Phải hỗ trợ giao thức AMQP tiêu chuẩn và RabbitMQ Quorum Queues.

---

## Các Phương án Đang Đánh giá

### Phương án 1: RabbitMQ trên EKS (Operator Kubernetes RabbitMQ Cluster Chính thức)
* **Mô tả**: Triển khai các stateful set RabbitMQ sử dụng VMware/RabbitMQ Cluster Operator chính thức trên EKS backed bởi các EBS `gp3` volumes trên 3 AZs.
* **Ưu điểm**: Khai báo custom resource definitions (CRDs); tích hợp Kubernetes native; không tốn phí instance managed Amazon MQ; dễ tương thích môi trường phát triển local.
* **Nhược điểm**: Đội ngũ SRE phải giám sát trạng thái cơ sở dữ liệu Erlang Mnesia, xử lý khôi phục phân tách mạng và quản lý mở rộng lưu trữ EBS.
* **Tác động Bảo mật**: Tốt. Mã hóa TLS transport, SecurityContext cho pod và tích hợp IAM IRSA.
* **Tác động Sẵn sàng**: Mạnh khi cấu hình với Quorum Queues trên 3 AZs.
* **Tác động Mở rộng**: Mở rộng pod động và mở rộng dung lượng lưu trữ.
* **Tác động Vận hành**: Trách nhiệm vận hành Trung bình-Cao cho tinh chỉnh Erlang VM (`RSK-OPS-001`).
* **Tác động Chi phí**: Hiệu quả chi phí rất cao (tận dụng tính toán/lưu trữ worker node EKS sẵn có).
* **Phụ thuộc Nhà cung cấp**: Rất Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Có sẵn dung lượng tính toán EKS và EBS `gp3` storage driver.
* **Rủi ro**: Lỗi split-brain phân tách mạng Erlang khi có sự cố mạng xuyên AZ.

### Phương án 2: Amazon MQ for RabbitMQ (Dịch vụ Managed)
* **Mô tả**: Sử dụng dịch vụ Amazon MQ managed của AWS cho RabbitMQ triển khai Multi-AZ active/standby hoặc cluster.
* **Ưu điểm**: AWS quản lý cấp phát broker, vá lỗi OS/Erlang, thiết lập và nhân bản multi-AZ.
* **Nhược điểm**: Giá theo giờ instance cao hơn đáng kể; hạn chế truy cập cấu hình Erlang VM bên dưới; giới hạn dung lượng lưu trữ hàng chờ tùy thuộc loại instance.
* **Tác động Bảo mật**: Rất tốt. Mã hóa KMS at rest, TLS in transit, cô lập security group VPC.
* **Tác động Sẵn sàng**: Cao (SLA 99.9%).
* **Tác động Mở rộng**: Mở rộng instance theo chiều dọc đòi hỏi cửa sổ bảo trì broker.
* **Tác động Vận hành**: Gánh nặng bảo trì vận hành tối thiểu cho đội DevOps.
* **Tác động Chi phí**: Chi phí phí broker managed AWS hàng tháng cao.
* **Phụ thuộc Nhà cung cấp**: Thấp-Trung bình (Tương thích giao thức AMQP tiêu chuẩn).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược kèm di chuyển.
* **Điều kiện tiên quyết**: Subnet VPC Chuyên trách.
* **Rủi ro**: Chi phí tăng nhanh nếu thể tích tin nhắn mở rộng đột biến.

### Phương án 3: Cluster EC2 Chuyên trách cho RabbitMQ
* **Mô tả**: Cấp phát các instance EC2 chuyên trách chạy cluster RabbitMQ quản lý qua Ansible.
* **Ưu điểm**: Tách biệt hoàn toàn trạng thái message broker khỏi vòng đời EKS cluster.
* **Nhược điểm**: Đòi hỏi quản lý vòng đời instance EC2 thủ công, vá lỗi OS và các script bảo trì Ansible tùy chỉnh.
* **Tác động Bảo mật**: Trung bình.
* **Tác động Sẵn sàng**: Trung bình.
* **Tác động Mở rộng**: Cấp phát instance EC2 thủ công.
* **Tác động Vận hành**: Gánh nặng vận hành cao.
* **Tác động Chi phí**: Trung bình.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Trung bình.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Các script quản lý cấu hình Ansible (`FUN-004`).
* **Rủi ro**: Lỗi bảo trì thủ công trong quá trình vá lỗi OS.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: RabbitMQ trên EKS Operator | Phương án 2: Amazon MQ for RabbitMQ | Phương án 3: EC2 Chuyên trách |
| :--- | :--- | :--- | :--- |
| **Chi phí Nhân công Vận hành** | Trung bình | **Tối thiểu** | Nặng |
| **Tích hợp K8s (`BUS-002`)** | **Mạnh (Operator Native)** | Trung bình (Endpoint AMQP) | Trung bình |
| **Hiệu quả Chi phí (`CST-001`)** | **Cao** | Yếu (Phí AWS Cao) | Trung bình |
| **Độ Bền vững (Quorum Queues)** | **Mạnh** | Mạnh | Trung bình |
| **Khả năng Đảo ngược** | **Dễ dàng Đảo ngược** | Có thể đảo ngược | Có thể đảo ngược |

---

## Quyết định Đề xuất
**Quyết định bị Tạm hoãn (Deferred)**.

---

## Lý do Lựa chọn
Lựa chọn giữa RabbitMQ Cluster Operator trên EKS (Phương án 1) và Amazon MQ for RabbitMQ (Phương án 2) **được tạm hoãn chờ các chỉ số thể tích tin nhắn và băng thông** (`OPEN-001`).

Phương án 1 hiện là ứng viên kỹ thuật dẫn đầu nhờ độ chín của Operator tiêu chuẩn và hiệu quả chi phí, nhưng cần xác minh đối với các mục tiêu độ bền vững tin nhắn của khách hàng.

---

## Bằng chứng Xác minh Cần thiết trước khi Phê duyệt
1. Thể tích tin nhắn microservice (msg/sec), dung lượng payload trung bình và mục tiêu lưu trữ hàng chờ (`OPEN-001`).
2. Đánh giá năng lực vận hành RabbitMQ / Erlang VM của đội ngũ SRE.

## Điều kiện Nghiệm thu
* Nộp các benchmark truyền tin nhắn được xác minh và phê duyệt chính thức từ Hội đồng Kiến trúc.

## Triggers Xem xét lại
* Hoàn thành đo đạc tải công việc trong Phase 1.

## Tác động Triển khai
* Kiến trúc nền tảng phân bổ namespace EKS và các endpoint mạng cho định tuyến RabbitMQ.
