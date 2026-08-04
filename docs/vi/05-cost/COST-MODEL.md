# Mô hình Chi phí Tham số & Chú thích Công thức Chi tiết: Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Phương pháp Tính toán Chi phí Tham số**, các công thức toán học, định nghĩa biến số, tham số đơn giá và chú thích diễn giải chi tiết cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng yêu cầu `BUS-004` và [`REQUIREMENTS-REGISTER.md`](../01-requirements/REQUIREMENTS-REGISTER.md), tổng chi phí vận hành hàng tháng của nền tảng được tính bằng tổng của 6 danh mục chi phí cốt lõi:

$$\text{Tổng Chi phí AWS Hàng tháng} = C_{\text{Nền tảng Cố định}} + C_{\text{Tải Tính toán}} + C_{\text{Middleware}} + C_{\text{Lưu trữ/Sao lưu}} + C_{\text{Mạng}} + C_{\text{Quan sát}}$$

---

## 2. Công thức Tính toán Tổng thể & Chú thích Tham số Chi tiết

### 2.1 Chi phí Hạ tầng Nền tảng Cố định ($C_{\text{Nền tảng Cố định}}$)

Chi phí nền tảng cố định đại diện cho phần hạ tầng cơ sở bắt buộc phải duy trì 24/7/365 để đảm bảo EKS Control Plane, mạng VPC và các Load Balancers এবং vành đai hoạt động độc lập với lượng tải ứng dụng.

$$C_{\text{Nền tảng Cố định}} = (N_{\text{Clusters}} \times P_{\text{EKS Control Plane}}) + (N_{\text{VPCs}} \times N_{\text{AZs}} \times P_{\text{NAT Gateway Hour}}) + (N_{\text{ALBs}} \times P_{\text{ALB Hour}})$$

#### Định nghĩa Biến số & Chú thích Diễn giải:
* $N_{\text{Clusters}}$: Số lượng EKS clusters hoạt động ($N = 2$: 1 Test Cluster + 1 Prod Cluster).
* $P_{\text{EKS Control Plane}}$: Đơn giá giờ cho EKS managed control plane ($\text{USD } 0.10/\text{giờ} \approx \text{USD } 73.00/\text{tháng mỗi cluster}$).
* $N_{\text{VPCs}}$: Số lượng Virtual Private Clouds cô lập ($N = 2$: 1 Test VPC + 1 Prod VPC).
* $N_{\text{AZs}}$: Số lượng Availability Zones mỗi VPC ($N = 2$ cho Test, $N = 3$ cho Prod).
* $P_{\text{NAT Gateway Hour}}$: Chi phí cố định giờ mỗi NAT Gateway ($\text{USD } 0.045/\text{giờ} \approx \text{USD } 32.85/\text{tháng mỗi gateway}$).
* $N_{\text{ALBs}}$: Số lượng AWS Application Load Balancers ($N = 2$: 1 Test Public ALB + 1 Prod Public ALB).
* $P_{\text{ALB Hour}}$: Chi phí giờ cố định mỗi ALB ($\text{USD } 0.0225/\text{giờ} \approx \text{USD } 16.425/\text{tháng mỗi ALB}$).

#### Tính toán Cơ sở:
$$C_{\text{Nền tảng Cố định}} = (2 \times 73.00) + (1 \times 2 \times 32.85 + 1 \times 3 \times 32.85) + (2 \times 16.425) = 146.00 + 164.25 + 32.85 = \text{USD } 343.10/\text{tháng}$$

---

### 2.2 Chi phí Tải Tính toán Worker Nodes ($C_{\text{Tải Tính toán}}$)

Chi phí tải tính toán bao gồm năng lực EC2 worker nodes được tự động cấp phát Just-in-Time (JIT) bởi **Karpenter Autoscaler** ([`ADR-005`](../03-decisions/ADR-005-karpenter-autoscaler.md)) để vận hành ~40 microservice Pods.

$$C_{\text{Tải Tính toán}} = \sum_{i=1}^{N_{\text{Nodes}}} \left( \text{vCPU}_i \times P_{\text{vCPU-Hour}} + \text{RAM}_i \times P_{\text{RAM-Hour}} \right) \times 730 \times (1 - D_{\text{Tầng Giá}}$$

#### Định nghĩa Biến số & Chú thích Diễn giải:
* $N_{\text{Nodes}}$: Tổng số lượng worker nodes đang chạy thực tế trong cluster.
* $\text{vCPU}_i$: Năng lực vCPU cấp phát trên node $i$ (ví dụ: `m6g.large` = 2 vCPUs).
* $\text{RAM}_i$: Dung lượng RAM (GB) cấp phát trên node $i$ (ví dụ: `m6g.large` = 8 GB RAM).
* $P_{\text{vCPU-Hour}}$: Đơn giá giờ chuẩn cho vCPU Graviton3 ARM64 ($\approx \text{USD } 0.0255/\text{vCPU-giờ}$).
* $P_{\text{RAM-Hour}}$: Đơn giá giờ chuẩn cho GB RAM ($\approx \text{USD } 0.0034/\text{GB-giờ}$).
* $D_{\text{Tầng Giá}}$: Tỷ lệ chiết khấu tài chính áp dụng theo tầng môi trường:
  * **Môi trường Test (Spot)**: $D_{\text{Spot}} = 0.70$ (Giảm giá 70% qua Karpenter Spot Node Pools).
  * **Môi trường Production (Savings Plans)**: $D_{\text{Savings Plan}} = 0.35$ (Giảm giá 35% qua Compute Savings Plans 3 năm).

---

### 2.3 Chi phí Tầng Stateful Middleware ($C_{\text{Middleware}}$)

Chi phí middleware chi trả cho 5 nền tảng lưu trữ và truyền thông điệp cốt lõi: CSDL Quan hệ (MySQL), Bộ nhớ đệm (Redis), Hàng chờ Thông điệp (RabbitMQ), CSDL Bản ghi (MongoDB), và Trung tâm Cấu hình (Nacos).

$$C_{\text{Middleware}} = C_{\text{MySQL}} + C_{\text{Redis}} + C_{\text{RabbitMQ}} + C_{\text{MongoDB}} + C_{\text{Nacos}}$$

#### Định nghĩa Biến số & Chú thích Diễn giải:
* $C_{\text{MySQL}}$: **Amazon RDS MySQL Multi-AZ** (hoặc **Amazon Aurora MySQL** ở Kịch bản 3 Sẵn sàng cao Nâng cao) (`db.m6g.xlarge` Primary + Standby = $\text{USD } 520.00 - 1,450.00/\text{tháng}$).
* $C_{\text{Redis}}$: **Amazon ElastiCache for Redis Multi-AZ** (`cache.m6g.large` Cluster 2-Node = $\text{USD } 140.00 - 480.00/\text{tháng}$).
* $C_{\text{RabbitMQ}}$: **Amazon MQ for RabbitMQ** (Quorum Broker 3-node HA = $\text{USD } 280.00 - 420.00/\text{tháng}$).
* $C_{\text{MongoDB}}$: **Amazon DocumentDB Cluster 3-Node** (`db.t4g.medium` hoặc `db.m6g.large` = $\text{USD } 220.00 - 680.00/\text{tháng}$).
* $C_{\text{Nacos}}$: **Cluster Đồng thuận Raft 3-Node** chạy dưới dạng StatefulSets trên EKS compute ($\text{USD } 90.00 - 180.00/\text{tháng}$).

---

### 2.4 Chi phí Lưu trữ & Sao lưu ($C_{\text{Lưu trữ/Sao lưu}}$)

Chi phí lưu trữ bao gồm dung lượng đĩa EBS cho EKS nodes, lưu trữ CSDL, lưu trữ đối tượng S3 và các bản sao lưu snapshot.

$$C_{\text{Lưu trữ/Sao lưu}} = (V_{\text{EBS gp3}} \times P_{\text{EBS}}) + (IOPS_{\text{Extra}} \times P_{\text{IOPS}}) + (V_{\text{S3 Standard}} \times P_{\text{S3 Standard}}) + (V_{\text{S3 Glacier}} \times P_{\text{Glacier}}) + (V_{\text{Snapshots}} \times P_{\text{Snapshot}})$$

#### Định nghĩa Biến số & Chú thích Diễn giải:
* $V_{\text{EBS gp3}}$: Dung lượng đĩa EBS gp3 cấp phát tính bằng GB ($P_{\text{EBS}} = \text{USD } 0.08/\text{GB-tháng}$).
* $IOPS_{\text{Extra}}$: Số lượng IOPS vượt mức baseline 3,000 IOPS ($P_{\text{IOPS}} = \text{USD } 0.005/\text{IOPS cấp phát-tháng}$).
* $V_{\text{S3 Standard}}$: Dung lượng lưu trữ đối tượng S3 Standard tính bằng GB ($P_{\text{S3 Standard}} = \text{USD } 0.023/\text{GB-tháng}$).
* $V_{\text{S3 Glacier}}$: Dung lượng lưu trữ lưu trữ dài hạn S3 Glacier Flexible Archive ($P_{\text{Glacier}} = \text{USD } 0.004/\text{GB-tháng}$).
* $V_{\text{Snapshots}}$: Bản sao lưu tự động EBS và RDS snapshot ($P_{\text{Snapshot}} = \text{USD } 0.05/\text{GB-tháng}$).

---

### 2.5 Chi phí Mạng & Truyền Dữ liệu ($C_{\text{Mạng}}$)

Chi phí mạng bao gồm lượng dữ liệu xử lý qua NAT Gateways, lưu lượng truyền liên AZ trong AWS region và lưu lượng ra Internet.

$$C_{\text{Mạng}} = (G_{\text{NAT Xử lý}} \times P_{\text{NAT Data}}) + (G_{\text{Inter-AZ Data}} \times P_{\text{Inter-AZ}}) + (G_{\text{Internet Ra}} \times P_{\text{Egress}})$$

#### Định nghĩa Biến số & Chú thích Diễn giải:
* $G_{\text{NAT Xử lý}}$: Dung lượng dữ liệu xử lý qua NAT Gateways tính bằng GB ($P_{\text{NAT Data}} = \text{USD } 0.045/\text{GB}$).
* $G_{\text{Inter-AZ Data}}$: Lưu lượng truyền qua lại giữa các Availability Zones giữa Pods và CSDL ($P_{\text{Inter-AZ}} = \text{USD } 0.01/\text{GB truyền đi/vào}$).
* $G_{\text{Internet Ra}}$: Lưu lượng truyền ra Internet cho người dùng cuối và đối tác ($P_{\text{Egress}} = \text{USD } 0.09/\text{GB}$).

---

### 2.6 Chi phí Quan sát & Vận hành ($C_{\text{Quan sát}}$)

Chi phí quan sát bao gồm hệ thống ghi log tập trung, giám sát chỉ số Prometheus/Grafana và nhật ký kiểm toán.

$$C_{\text{Quan sát}} = C_{\text{OpenSearch Cluster}} + (G_{\text{Log Nạp}} \times P_{\text{Ingest}}) + (G_{\text{S3 Log Archive}} \times P_{\text{Archive}})$$

#### Định nghĩa Biến số & Chú thích Diễn giải:
* $C_{\text{OpenSearch Domain}}$: **Amazon OpenSearch Service** (Cluster 2-node hoặc 4-node index log = $\text{USD } 180.00 - 650.00/\text{tháng}$).
* $G_{\text{Log Nạp}}$: Tổng dung lượng log ứng dụng thu gom bởi Fluent Bit daemonset ($P_{\text{Ingest}} = \text{USD } 0.50/\text{GB}$).
* $G_{\text{S3 Log Archive}}$: Lưu trữ log dài hạn trên S3 tuân thủ pháp lý ($P_{\text{Archive}} = \text{USD } 0.004/\text{GB-tháng}$).

---

## 3. Tóm tắt 4 Kịch bản Tài chính Chuẩn hóa

Áp dụng mô hình chi phí tham số cho 4 kịch bản dự án chuẩn hóa thu được ngân sách cơ sở như sau:

| Kịch bản Tài chính FinOps | Quy mô EKS Worker Nodes | Topo Middleware | Ngân sách Cơ sở Hàng tháng | Vai trò Kiến trúc |
| :--- | :--- | :--- | :--- | :--- |
| **Kịch bản 1: Test Tiêu chuẩn Non-Prod** | 2 AZs, ~8 Nodes `m6g.large`, 70% Spot | CSDL Đơn bản thể / Rút gọn | **USD 1,600 – 2,400 / tháng** | Môi trường Kiểm thử Non-Prod & QA |
| **Kịch bản 2: Production Cơ sở** | 3 AZs, ~12 Nodes `m6g.large`, Savings Plans 3 năm | RDS MySQL Multi-AZ, OpenSearch 2-Node | **USD 4,200 – 6,100 / tháng** | Vận hành Production Cơ sở |
| **Kịch bản 3: Production Sẵn sàng Cao Nâng cao** | 3 AZs, Transit Gateway, ~24 Nodes | Aurora MySQL 3 Replicas, Redis Sharded | **USD 7,200 – 10,500 / tháng** | Production Tải Cao Cao điểm |
| **Kịch bản 4: Production Khôi phục Thảm họa Xuyên Vùng** | Primary `us-east-1` + Standby `us-west-2` | Nhân bản Xuyên Vùng, Cloudflare GTM | **USD 10,000 – 14,800 / tháng** | Khôi phục Thảm họa Multi-Region Complete |
