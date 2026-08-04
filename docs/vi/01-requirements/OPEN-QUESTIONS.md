# Nhật ký Câu hỏi Mở (Open Questions Register): Nền tảng AWS Kubernetes DataBlue

---

## 1. Tổng quan

Tài liệu này theo dõi các câu hỏi mở ưu tiên về kiến trúc, vận hành và tài chính cho **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`).

Các câu hỏi tập trung vào những quyết định có tác động lớn, ảnh hưởng trực tiếp tới thiết kế kiến trúc AWS, topo hạ tầng, ranh giới bảo mật và chi tiêu đám mây AWS.

---

## 2. Các Câu hỏi Tác động lớn về Kiến trúc & Chi phí

### `OPEN-001`: Đo đạc Tải công việc Microservice & Định kích thước Tài nguyên
* **Mức độ Tác động**: **NGHIÊM TRỌNG (CRITICAL)** (Ảnh hưởng trực tiếp đến kích thước node EKS, họ instance EC2 và tổng chi phí AWS).
* **Câu hỏi**: Dữ liệu chỉ số trung bình và đỉnh về CPU, Bộ nhớ (RAM), IOPS Lưu trữ và Băng thông Mạng của từng microservice trong số ~40 microservices thuộc 5–6 hệ thống nghiệp vụ là bao nhiêu?
* **Tại sao Quan trọng**: Nếu không có dữ liệu kích thước, việc cấp phát node sẽ dựa vào các giả định tạm thời (`ASM-006`), nguy cơ lãng phí chi phí hoặc thiếu hụt tài nguyên.
* **Giai đoạn Quyết định Mục tiêu**: Phase 1 / Phase 2 (Trước khi chốt kích thước trong mã IaC).
* **Hành động Yêu cầu**: Khách hàng chạy công cụ đo đạc tải hoặc cung cấp chỉ số máy chủ legacy.

---

### `OPEN-002`: Mô hình Triển khai Middleware Lưu trạng thái (Managed AWS vs Self-Hosted trên EKS)
* **Mức độ Tác động**: **NGHIÊM TRỌNG (CRITICAL)** (Ảnh hưởng đến độ phức tạp vận hành, tự động hóa sao lưu/DR và chi tiêu hàng tháng AWS).
* **Câu hỏi**: Đối với MySQL, RabbitMQ, MongoDB, Redis và Nacos, tổ chức ưu tiên phương án nào:
  1. Dịch vụ AWS Managed Hoàn toàn (ví dụ: AWS RDS MySQL, Amazon ElastiCache Redis, Amazon DocumentDB / MongoDB Atlas, Amazon MSK / Self-Hosted RabbitMQ trên EC2)?
  2. Các Middleware Operator Self-Hosted triển khai trực tiếp bên trong EKS (ví dụ: ECK, KubeBlocks, Bitnami Helm Chart Operators với EBS persistent volumes)?
* **Tại sao Quan trọng**: Dịch vụ Managed giảm gánh nặng vận hành nhưng tăng chi phí hóa đơn AWS; Operator trên EKS giảm phụ thuộc nhà cung cấp đám mây nhưng yêu cầu đội ngũ SRE bảo trì chuyên trách.
* **Giai đoạn Quyết định Mục tiêu**: Phase 1 (Sẽ được đánh giá qua quy trình ADR chính thức).
* **Hành động Yêu cầu**: Đội ngũ Kiến trúc trình bày so sánh TCO & độ phức tạp vận hành.

---

### `OPEN-003`: Chỉ số SLA Khả năng Sẵn sàng Vùng & Khôi phục Thảm họa (DR) Mục tiêu
* **Mức độ Tác động**: **CAO (HIGH)** (Ảnh hưởng đến yêu cầu RTO/RPO, phí truyền dữ liệu xuyên vùng và kiến trúc đa vùng).
* **Câu hỏi**: Chỉ số mục tiêu thời gian khôi phục (RTO - Recovery Time Objective) và điểm khôi phục (RPO - Recovery Point Objective) cụ thể cho từng hệ thống trong số 5–6 hệ thống nghiệp vụ khi xảy ra sự cố vùng là bao nhiêu?
* **Tại sao Quan trọng**: Sẵn sàng Cao (Multi-AZ trong 1 vùng) bảo vệ khỏi sự cố node/vùng. Khôi phục Thảm họa Toàn diện (Failover Xuyên Vùng) yêu cầu nhân bản active-passive hoặc active-active, làm tăng gấp đôi chi phí hạ tầng cơ sở.
* **Giai đoạn Quyết định Mục tiêu**: Phase 1 ADR.
* **Hành động Yêu cầu**: Chủ sở hữu Sản phẩm Nghiệp vụ định nghĩa phân tầng tính liên tục nghiệp vụ.

---

### `OPEN-004`: Kết nối Mạng & Tích hợp On-Premises / Multi-Cloud
* **Mức độ Tác động**: **CAO (HIGH)** (Ảnh hưởng đến phân bổ CIDR AWS VPC, thiết lập Transit Gateway, chi phí AWS Direct Connect / VPN).
* **Câu hỏi**: Có hệ thống nào trong số 5–6 hệ thống nghiệp vụ yêu cầu kết nối lai (hybrid) về trung tâm dữ liệu On-Premises, cổng thanh toán bên thứ ba hoặc cơ sở dữ liệu legacy qua AWS Direct Connect / Site-to-Site VPN không?
* **Tại sao Quan trọng**: Quyết định bố trí mạng VPC, định kích thước băng thông NAT Gateway, định tuyến transit và chính sách lọc bảo mật lai.
* **Giai đoạn Quyết định Mục tiêu**: Phase 1 Thiết kế Kiến trúc.
* **Hành động Yêu cầu**: Đội ngũ Hạ tầng Mạng Khách hàng cung cấp sơ đồ tích hợp mạng.

---

### `OPEN-005`: Quản trị Đa Tài khoản & Khung Tuân thủ Bảo mật
* **Mức độ Tác động**: **TRUNG BÌNH-CAO (MEDIUM-HIGH)** (Ảnh hưởng đến AWS Control Tower, IAM Identity Center / SSO, nhật ký kiểm toán, phạm vi tuân thủ).
* **Câu hỏi**: Tổ chức có bắt buộc thực thi khung tuân thủ quy định cụ thể nào không (ví dụ: PCI-DSS, ISO 27001, SOC2, HIPAA), và đã có sẵn landing zone AWS Organizations / Control Tower chưa?
* **Tại sao Quan trọng**: Phân định ranh giới chính sách bảo mật, tập trung nhật ký CloudTrail, quy tắc xoay vòng key KMS và tích hợp IAM.
* **Giai đoạn Quyết định Mục tiêu**: Alignment Quản trị Phase 0 / Phase 1.
* **Hành động Yêu cầu**: Đội ngũ Bảo mật & Tuân thủ Khách hàng xác nhận yêu cầu kiểm toán.

---

### `OPEN-006`: Tự động hóa Pipeline CI/CD & Ranh giới Quản trị
* **Mức độ Tác động**: **TRUNG BÌNH (MEDIUM)** (Ảnh hưởng đến luồng công việc lập trình viên, cấu trúc container registry, quản lý secret).
* **Câu hỏi**: Các secret (thông tin đăng nhập DB, API key, certificate) sẽ được nạp như thế nào xuyên suốt pipeline triển khai GitLab → Jenkins → Ansible → EKS (ví dụ: AWS Secrets Manager, HashiCorp Vault, hay Sealed Secrets)?
* **Tại sao Quan trọng**: Ngăn ngừa secret bị hardcode trong pipeline và thiết lập các nguyên tắc thực thi GitOps / Ansible bảo mật.
* **Giai đoạn Quyết định Mục tiêu**: Phase 2 Thiết kế Kỹ thuật Chi tiết.
* **Hành động Yêu cầu**: Thống nhất đội ngũ DevOps về bộ công cụ lưu trữ secret.
