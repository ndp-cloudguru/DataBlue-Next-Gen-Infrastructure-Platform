# Kế hoạch Triển khai Middleware (Middleware Delivery Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định các lộ trình triển khai riêng biệt, topo sẵn sàng cao, phương pháp sao lưu, và vòng đời vận hành cho năm dịch vụ middleware stateful được yêu cầu bởi **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`):
1. **MySQL** (`FUN-005`)
2. **Redis** (`FUN-008`)
3. **RabbitMQ** (`FUN-006`)
4. **MongoDB** (`FUN-007`)
5. **Nacos** (`FUN-009`)

Các ADR Phase 3 chưa được giải quyết (`ADR-006`..`009`) được làm nổi bật cùng với các bằng chứng cần thiết để mở khóa.

---

## 2. Quy cách Triển khai Thành phần Middleware

### 2.1 Cơ sở Dữ liệu Quan hệ MySQL (`FUN-005`)
* **Mô hình Triển khai Đề xuất / Ứng viên**: Amazon RDS for MySQL (Multi-AZ) vs. Self-Hosted MySQL Operator trên EKS (`Ứng viên ADR: ADR-006`).
* **Trạng thái ADR chưa Giải quyết**: **`Deferred`** (Tạm hoãn) (`ADR-006`).
* **Bằng chứng Cần thiết để Mở khóa**: Kích thước lưu trữ DB, IOPS giao dịch, và tỷ lệ đọc/ghi từ Giai đoạn 0 (`OPEN-001`).
* **Topo Môi trường**: Instance Primary tại AZ-a, instance Standby đồng bộ tại AZ-b (Các Subnet Database VPC).
* **Mô hình Sẵn sàng Cao (HA)**: Failover Multi-AZ tự động (< 60 giây) với chuyển đổi DNS CNAME (`NFR-001`).
* **Phương pháp Sao lưu & Khôi phục**: Snapshot tự động hàng ngày + Nhật ký giao dịch liên tục Khôi phục Point-in-Time (PITR) 30 ngày (`ADR-013`). Xác minh khôi phục tự động hàng tháng sang các subnet Test cô lập (`RSK-DAT-002`).
* **Giám sát & Cảnh báo**: AWS CloudWatch + Các chỉ số Prometheus mysqld_exporter (Connection count > 80%, CPU > 85%, Storage Free < 15%).
* **Phương pháp Mở rộng**: Thay đổi kích thước instance theo chiều dọc (`db.m6g.xlarge`) + Giải phóng tải qua endpoint Read-Replica (`NFR-004`).
* **Phương pháp Nâng cấp**: Nâng cấp phiên bản nhỏ engine do AWS managed trong cửa sổ bảo trì.
* **Khôi phục Sự cố**: Tự động thăng cấp instance secondary khi host primary hoặc AZ gặp sự cố.
* **Yêu cầu Di chuyển Dữ liệu**: Nạp schema ban đầu và dữ liệu seed qua `mysqldump` / Dịch vụ Di chuyển Cơ sở Dữ liệu AWS (DMS).

---

### 2.2 Bộ nhớ in-Memory Cache Redis (`FUN-008`)
* **Mô hình Triển khai Đề xuất / Ứng viên**: Amazon ElastiCache for Redis vs. Self-Hosted Redis Cluster trên EKS (`Ứng viên ADR: ADR-007`).
* **Trạng thái ADR chưa Giải quyết**: **`Deferred`** (Tạm hoãn) (`ADR-007`).
* **Bằng chứng Cần thiết để Mở khóa**: Dung lượng RAM bộ nhớ cache và hồ sơ chính sách eviction (`OPEN-001`).
* **Topo Môi trường**: Group Nhân bản 2-node / 3-node trải rộng trên AZ-a, AZ-b, và AZ-c (Subnet Database).
* **Mô hình Sẵn sàng Cao (HA)**: Failover primary/replica Multi-AZ (< 30 giây) với định tuyến endpoint tự động.
* **Phương pháp Sao lưu**: Xuất RDB snapshot tự động hàng ngày sang S3 (`ADR-013`).
* **Giám sát & Cảnh báo**: Các cảnh báo metric ElastiCache `EngineCPUUtilization`, `DatabaseMemoryUsagePercentage`, và `CacheMissRate`.
* **Phương pháp Mở rộng**: Thay đổi kích thước node instance online (`cache.m6g.large`) và mở rộng shard cluster.
* **Phương pháp Nâng cấp**: Cập nhật phiên bản managed trong cửa sổ bảo trì.
* **Khôi phục Sự cố**: Tự động failover node primary sang replica secondary.
* **Yêu cầu Di chuyển Dữ liệu**: Làm nóng (warming) cache tạm thời qua logic ứng dụng.

---

### 2.3 Message Broker RabbitMQ (`FUN-006`)
* **Mô hình Triển khai Đề xuất / Ứng viên**: RabbitMQ Cluster Kubernetes Operator trên EKS vs. Amazon MQ for RabbitMQ (`Ứng viên ADR: ADR-008`).
* **Trạng thái ADR chưa Giải quyết**: **`Deferred`** (Tạm hoãn) (`ADR-008`).
* **Bằng chứng Cần thiết để Mở khóa**: Băng thông tin nhắn (msg/sec), độ sâu hàng chờ, và chỉ số dung lượng payload (`OPEN-001`).
* **Topo Môi trường**: Erlang cluster 3-node triển khai trên AZ-a, AZ-b, và AZ-c.
* **Mô hình Sẵn sàng Cao (HA)**: Quorum Queues được nhân bản trên 3 nodes (`NFR-001`).
* **Phương pháp Sao lưu**: Velero EKS state volume backups + Xuất file JSON định nghĩa RabbitMQ (`ADR-013`).
* **Giám sát & Cảnh báo**: Cảnh báo Prometheus `rabbitmq_queue_messages_ready` và `rabbitmq_erlang_mem_limit`.
* **Phương pháp Mở rộng**: Mở rộng pod replica động + Tự động mở rộng lưu trữ EBS `gp3`.
* **Phương pháp Nâng cấp**: Thay thế cuộn (rolling) StatefulSet pod qua RabbitMQ Operator.
* **Khôi phục Sự cố**: Bầu chọn lại leader quorum queue khi node bị crash.
* **Yêu cầu Di chuyển Dữ liệu**: Khai báo lại các định nghĩa exchange và queue qua Ansible (`FUN-004`).

---

### 2.4 Cơ sở Dữ liệu Tài liệu MongoDB (`FUN-007`)
* **Mô hình Triển khai Đề xuất / Ứng viên**: MongoDB Operator trên EKS vs. MongoDB Atlas vs. Amazon DocumentDB (`Ứng viên ADR: ADR-009`).
* **Trạng thái ADR chưa Giải quyết**: **`Deferred`** (Tạm hoãn) (`ADR-009`).
* **Bằng chứng Cần thiết để Mở khóa**: **BẮT BỘC KIỂM TOÁN các truy vấn ứng dụng đối chiếu với độ tương thích wire-protocol của DocumentDB** (`RSK-DAT-001`).
* **Topo Môi trường**: Replica Set 3 thành viên (1 Primary, 2 Secondaries) trên 3 AZs.
* **Mô hình Sẵn sàng Cao (HA)**: Bầu chọn replica set tự động (< 15 giây) khi primary gặp sự cố.
* **Phương pháp Sao lưu**: Snapshots volume hàng ngày + Lưu trữ liên tục oplog cho PITR 30 ngày (`ADR-013`).
* **Giám sát & Cảnh báo**: Cảnh báo exporter MongoDB `opcounter`, `asserts`, và `mem_resident`.
* **Phương pháp Mở rộng**: Thay đổi kích thước node theo chiều dọc + Sharding MongoDB.
* **Phương pháp Nâng cấp**: Nâng cấp cuộn từng thành viên replica set (Secondaries trước, Primary sau cùng).
* **Khôi phục Sự cố**: Bầu chọn thành viên secondary tự động.
* **Yêu cầu Di chuyển Dữ liệu**: `mongodump` / `mongorestore` hoặc công cụ MongoDB Relocate.

---

### 2.5 Nacos Service Discovery & Cấu hình Động (`FUN-009`)
* **Mô hình Triển khai Đề xuất / Ứng viên**: Nacos Cluster StatefulSet trên EKS (`ADR-010`).
* **Trạng thái ADR chưa Giải quyết**: **`Proposed`** (Đề xuất) (`ADR-010`).
* **Topo Môi trường**: Nacos Raft cluster 3-node triển khai trên AZ-a, AZ-b, và AZ-c trong các Subnet Application Private.
* **Mô hình Sẵn sàng Cao (HA)**: Đồng thuận Nacos Raft quorum được backed bởi tầng cơ sở dữ liệu quan hệ MySQL.
* **Phương pháp Sao lưu**: Dữ liệu cấu hình Nacos được sao lưu qua snapshot cơ sở dữ liệu MySQL (`ADR-013`).
* **Giám sát & Cảnh báo**: Các chỉ số sức khỏe actuator Nacos + Theo dõi connection pool MySQL.
* **Phương pháp Mở rộng**: Mở rộng pod replica theo chiều ngang (`3` → `5` nodes).
* **Phương pháp Nâng cấp**: Cập nhật ảnh StatefulSet theo phương thức rolling.
* **Khôi phục Sự cố**: Bầu chọn lại leader Nacos Raft.
* **Yêu cầu Di chuyển Dữ liệu**: Xuất/nhập các file zip cấu hình Nacos.
