# Các Giả định Chi phí (Cost Assumptions): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định tất cả các giả định tài chính và kỹ thuật được sử dụng để xây dựng **Mô hình Chi phí Tham số (Parametric Cost Model)** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng yêu cầu `BUS-004` và các quy tắc quản trị:
* Các ước tính chi phí được **dựa trên kịch bản (Kịch bản A đến E)**, không phải là hóa đơn cố định duy nhất.
* Tất cả bảng giá sử dụng baseline giá chuẩn của AWS Region public (mức giá `us-east-1` / `ap-southeast-1`).
* Các tham số kích thước chưa được xác nhận được quản trị theo các hạng định kích thước dịch vụ dự kiến (XS, S, M, L, XL).

---

## 2. Các Giả định Tài chính & Kỹ thuật Cốt lõi

### 1. Tính toán & EKS Control Plane
* **EKS Control Plane**: Cố định $0.10 mỗi cluster mỗi giờ ($73.00 mỗi tháng) mỗi môi trường (`ADR-003`).
* **Mô hình Giá Worker Instance**:
  * Production: Baseline giá On-Demand 100%; Compute Savings Plans 3 năm mang lại mức giảm giá ~30-40%.
  * Test: 70% EC2 Spot instances (giảm ~70% so với On-Demand) + 30% On-Demand (`ADR-005`).
* **Mật độ Tài nguyên Microservice Dự kiến**: ~40 microservices phân bổ trên các hạng định kích thước:
  * Hạng XS (Siêu nhỏ): 0.1 vCPU, 0.25 GB RAM (10 dịch vụ)
  * Hạng S (Nhỏ): 0.25 vCPU, 0.5 GB RAM (15 dịch vụ)
  * Hạng M (Trung bình): 0.5 vCPU, 1.0 GB RAM (10 dịch vụ)
  * Hạng L (Lớn): 1.0 vCPU, 2.0 GB RAM (5 dịch vụ)

### 2. Mạng & Truyền Dữ liệu
* **NAT Gateways**: $0.045 mỗi NAT Gateway mỗi giờ ($32.85/tháng mỗi AZ) + $0.045 mỗi GB dữ liệu được xử lý.
* **Truyền Dữ liệu Xuyên AZ**: $0.01 mỗi GB lưu lượng intra-VPC inter-AZ. (Được tối ưu qua định tuyến topology-aware Kubernetes).
* **Internet Egress**: $0.09 mỗi GB ra internet công cộng cho 10 TB/tháng đầu tiên.

### 3. Tầng Cơ sở Dữ liệu & Stateful Middleware
* **MySQL Quan hệ (`FUN-005`)**: Amazon RDS MySQL `db.m6g.xlarge` Multi-AZ ($0.76/giờ) managed hoặc Self-Hosted trên tính toán EKS.
* **Redis in-Memory Cache (`FUN-008`)**: Amazon ElastiCache `cache.m6g.large` Multi-AZ ($0.136/giờ) managed hoặc Self-Hosted trên tính toán EKS.
* **Message Broker RabbitMQ (`FUN-006`)**: Amazon MQ `mq.m6g.large` Multi-AZ ($0.576/giờ) hoặc Operator Self-Hosted trên EKS.
* **Document Database MongoDB (`FUN-007`)**: Amazon DocumentDB `db.t4g.medium` / `db.r6g.xlarge` hoặc MongoDB Atlas SaaS hoặc Operator Self-Hosted trên EKS.

### 4. Vòng đời Lưu trữ & Sao lưu
* **Lưu trữ EBS (`gp3`)**: $0.08 mỗi GB-tháng + $0.005 mỗi IOPS cấp phát vượt quá 3,000 baseline.
* **Lưu trữ S3 Standard**: $0.023 mỗi GB-tháng cho các snapshot sao lưu active và xuất log.
* **S3 Glacier Flexible Retrieval**: $0.004 mỗi GB-tháng cho lưu trữ log dài hạn (sau 30 ngày).
* **AWS Backup Snapshots**: $0.05 mỗi GB-tháng cho lưu trữ sao lưu RDS/EBS (`ADR-013`).

### 5. Khả năng Quan sát & Nạp Log
* **Amazon OpenSearch**: Cluster 2-node `r6g.large.search` ($0.163/giờ) cho tìm kiếm log hot 7 ngày (`ADR-012`).
* **Nạp Log CloudWatch**: $0.50 mỗi GB dữ liệu log được nạp; được tối ưu bằng cách lọc log debug tại daemonset Fluent Bit (`RSK-CST-002`).

### 6. Hỗ trợ & Chi phí Vận hành
* **AWS Enterprise Support**: 10% chi tiêu AWS hàng tháng cho các tài khoản Production (mức tối thiểu $15,000 cho Enterprise đầy đủ).
