# Yêu cầu Phi Chức năng (Non-Functional Requirements): Nền tảng AWS Kubernetes DataBlue

---

## 1. Tổng quan

Tài liệu này quy định các thuộc tính chất lượng mục tiêu, hạn chế vận hành và yêu cầu phi chức năng cho **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`).

Nơi các chỉ số hiệu năng số, SLA hoặc benchmark kích thước cụ thể của khách hàng hiện chưa có sẵn, chỉ số mục tiêu được đánh dấu rõ ràng là **`TBD`** (Sẽ xác định sau), kèm theo giải thích về dữ liệu đo đạc thực nghiệm cần thiết để chốt ngưỡng cuối cùng.

---

## 2. Thuộc tính Chất lượng Kỹ thuật

### 2.1 Khả năng Sẵn sàng (Availability)
* **Topo Multi-AZ Control Plane & Worker**: Control plane EKS (do AWS quản lý trên 3 AZs) và các worker node phải duy trì phân bổ active multi-AZ trên ít nhất 3 Availability Zones trong vùng AWS mục tiêu.
* **SLA Uptime Nền tảng Mục tiêu**: **`TBD`**
  * *Dữ liệu Cần thiết*: Yêu cầu SLA nghiệp vụ theo từng tầng hệ thống. Ngưỡng cơ sở khuyến nghị là ≥99.9% cho Production và ≥99.0% cho Test.
* **Điểm Lỗi Đơn lẻ (SPOF)**: Không cho phép bất kỳ điểm lỗi đơn lẻ nào trong kiến trúc tính toán, mạng, ingress (AWS ALB) hoặc middleware lưu trạng thái ở môi trường Production.

---

### 2.2 Khả năng Mở rộng (Scalability)
Mở rộng hệ thống phải được phân tách rõ ràng thành ba tầng tách biệt:

1. **Mở rộng Ứng dụng Kubernetes (Mở rộng Linh hoạt Pod)**:
   * **Cơ chế**: Horizontal Pod Autoscaler (HPA) dựa trên mức sử dụng CPU/Memory, kết hợp với KEDA (Kubernetes Event-driven Autoscaling) cho chỉ số độ sâu hàng chờ RabbitMQ.
   * **Cửa sổ Phản hồi Mục tiêu**: **`TBD`**
   * *Dữ liệu Cần thiết*: Hồ sơ độ trễ khởi động của microservice và chỉ số đột biến tải kiểm thử.

2. **Mở rộng Node Kubernetes (Mở rộng Hạ tầng Cluster)**:
   * **Cơ chế**: Karpenter hoặc Cluster Autoscaler cấp phát động các instance EC2 (kết hợp On-Demand và Spot cho tải non-production).
   * **Thời gian Cấp phát Mục tiêu**: **`TBD`**
   * *Dữ liệu Cần thiết*: Thời gian benchmark khởi động node sử dụng pre-warmed AMI / Bottlerocket OS.

3. **Mở rộng Cơ sở Dữ liệu & Middleware**:
   * **Cơ chế**: Tách biệt tải đọc Read-Replica quan hệ (MySQL), sharding cluster Redis, mở rộng replica set MongoDB.
   * **Trần Kết nối & IOPS Mục tiêu**: **`TBD`**
   * *Dữ liệu Cần thiết*: Phân tích tỷ lệ đọc/ghi cơ sở dữ liệu và hồ sơ connection pool trên các microservices.

---

### 2.3 Hiệu năng (Performance)
* **Độ trễ API Ingress (P95 / P99)**: **`TBD`**
  * *Dữ liệu Cần thiết*: Baseline hiệu năng khách hàng hoặc yêu cầu hợp đồng SLA (ví dụ: độ trễ P95 < 200ms tại ranh giới AWS ALB).
* **Năng lực Băng thông (Peak Requests Per Second - RPS)**: **`TBD`**
  * *Dữ liệu Cần thiết*: Chỉ số thể tích giao dịch nghiệp vụ trên 5–6 hệ thống nghiệp vụ trong giờ cao điểm.
* **Lưu trữ IOPS & Độ trễ**: Provisioned IOPS (gp3/io2) cho lưu trữ cơ sở dữ liệu được cấu hình duy trì độ trễ đọc/ghi < 5ms.

---

### 2.4 Bảo mật & Quản lý Truy cập
* **Quản lý Định danh & Truy cập Đặc quyền Tối thiểu (IAM & RBAC)**:
  * AWS IAM Roles for Service Accounts (IRSA) được sử dụng duy nhất cho truy cập API AWS cấp Pod (không hardcode thông tin đăng nhập AWS).
  * Kubernetes RBAC tích hợp với SSO/OIDC doanh nghiệp cho truy cập cluster của người vận hành.
* **Phân tách Mạng & Bảo mật Ranh giới**:
  * Tải công việc Test và Production được cô lập vào các Tài khoản AWS riêng biệt.
  * Kubernetes NetworkPolicies thực thi quy tắc default-deny ingress/egress giữa các microservices.
  * AWS Security Groups thực thi lọc cổng nghiêm ngặt tại ranh giới mạng.
* **Cơ sở Mã hóa**:
  * Dữ liệu Lưu trữ (At Rest): Mã hóa sử dụng AWS KMS Customer-Managed Key (CMK) trên EBS, RDS, ElastiCache, S3 và EKS secrets (etcd encryption).
  * Dữ liệu Truyền tải (In Transit): Bắt buộc mã hóa TLS 1.3 trên tất cả cổng API ingress công cộng và TLS 1.2+ cho giao tiếp service-to-service nội bộ cluster.

---

### 2.5 Khả năng Khôi phục (Recoverability)
Định nghĩa tách biệt cho tính liên tục vận hành:

* **Sẵn sàng Cao (HA)**: Dư thừa Multi-AZ cung cấp vận hành liên tục khi có sự cố instance, pod hoặc Availability Zone đơn lẻ. RTO mục tiêu = 0 (Failover liền mạch).
* **Sao lưu Point-in-Time**: Chính sách vòng đời snapshot tự động hàng ngày cho MySQL, MongoDB, Redis và etcd với bản sao S3 xuyên vùng. Lưu trữ mục tiêu = 30 ngày (mặc định, chờ xác nhận tuân thủ).
* **Khôi phục Thảm họa (DR)**:
  * **RTO Mục tiêu (Recovery Time Objective)**: **`TBD`**
  * **RPO Mục tiêu (Recovery Point Objective)**: **`TBD`**
  * *Dữ liệu Cần thiết*: Phê duyệt Kế hoạch Liên tục Nghiệp vụ (BCP) chính thức chi tiết mức mất dữ liệu và thời gian gián đoạn chấp nhận được khi mất hoàn toàn một vùng AWS.

---

### 2.6 Khả năng Quan sát & Giám sát Máy chủ/Dịch vụ
* **Metrics & Giám sát Máy chủ/Dịch vụ**: Thu thập liên tục các metric node, container, pod, ingress và middleware qua Prometheus/Grafana hoặc AWS CloudWatch Container Insights.
* **Gom Log Tập trung**: Log ứng dụng stdout/stderr, log API ingress và log kiểm toán được chuyển về Amazon OpenSearch / CloudWatch với chính sách lưu trữ vòng đời tự động.
* **Distributed Tracing**: Tích hợp OpenTelemetry / AWS X-Ray tracing để trực quan hóa luồng yêu cầu trên ~40 microservices.
* **SLA Cảnh báo**: Cảnh báo PagerDuty / Slack tự động phát đi trong vòng < 2 phút khi vi phạm ngưỡng metric nghiêm trọng (ví dụ: lỗi node, pod crash loop, dung lượng lưu trữ > 85%).

---

### 2.7 Khả năng Bảo trì & Hạ tầng dạng Mã (IaC)
* **Hạ tầng Bất biến (Immutable Infrastructure)**: 100% hạ tầng AWS được cấp phát qua các module Terraform / OpenTofu có phiên bản, dạng mô-đun. Không cho phép sửa đổi thủ công trên AWS Console ở môi trường Production.
* **Triển khai GitOps Khai báo**: Tải công việc EKS cluster được quản lý theo phương pháp khai báo qua GitOps pipelines.
* **Nâng cấp Nền tảng Zero-Downtime**: Cập nhật EKS cluster và OS worker node được thực thi qua thay thế node pool blue/green xoay vòng không làm gián đoạn ứng dụng.

---

### 2.8 Kiểm soát Chi phí & Quản trị FinOps
* **Chính sách Gán Thẻ (Tag) Tài nguyên Bắt buộc**: 100% tài nguyên AWS được gán thẻ `Environment` (`Test`/`Prod`), `BusinessSystem`, `CostCenter`, `ManagedBy` (`Terraform`), và `Owner`.
* **Theo dõi Phân bổ Chi phí**: Bật phân rã AWS Cost Explorer tự động theo từng hệ thống nghiệp vụ và môi trường.
* **Rightsizing Non-Production Tự động**: Môi trường non-production (Test) được lên lịch tự động giảm quy mô node ngoài giờ làm việc (ví dụ: giảm node ban đêm/cuối tuần).
* **Phát hiện Bất thường Chi phí**: AWS Cost Anomaly Detection được cấu hình để thông báo cho trưởng nhóm FinOps trong 24 giờ khi chi tiêu đột biến ngoài dự kiến vượt 20% so với cơ sở.
