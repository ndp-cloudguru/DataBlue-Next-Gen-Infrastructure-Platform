# Chiến lược Kiểm thử & Kế hoạch Xác minh: Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Quản trị & Triết lý Kiểm thử

Tài liệu này định nghĩa **Chiến lược Kiểm thử** toàn diện để xác minh **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng các quy tắc quản trị:
* **Việc tạo xong hạ tầng KHÔNG PHẢI là bằng chứng chứng minh nền tảng hoạt động tốt**.
* **Triển khai thành công KHÔNG ĐỒNG NGHĨA VỚI sự sẵn sàng vận hành**.
* Sự sẵn sàng của nền tảng đòi hỏi các bằng chứng kiểm thử thực nghiệm cụ thể trên 11 miền xác minh.

---

## 2. 11 Miền Kiểm thử & Xác minh

### 1. Xác minh Hạ tầng (Infrastructure Validation)
* **Phạm vi**: Xác minh các subnet VPC, tuyến NAT, các key mã hóa AWS KMS, và liên kết IAM IRSA role.
* **Phương pháp Kiểm thử**: Xác minh module Terraform tự động (`terraform plan`, `tflint`, quét bảo mật `checkov`).
* **Tiêu chí Thành công**: 0 lỗi lint bảo mật; 100% lưu trữ EBS/RDS được mã hóa (`SEC-003`).

### 2. Xác minh Engine Nền tảng Kubernetes (Kubernetes Platform Engine Validation)
* **Phạm vi**: Độ trễ API server EKS control plane, phân giải CoreDNS, cấp phát IP pod của VPC CNI.
* **Phương pháp Kiểm thử**: Bộ kiểm thử tuân thủ Kubernetes Sonobuoy.
* **Tiêu chí Thành công**: 100% vượt qua kiểm thử tuân thủ API Kubernetes chuẩn.

### 3. Kiểm thử Bảo mật & Kiểm soát Truy cập (Security & Access Control Testing)
* **Phạm vi**: Các NetworkPolicy giữa các pod, phạm vi đặc quyền tối thiểu IAM IRSA, tích hợp Secrets Manager.
* **Phương pháp Kiểm thử**: Bơm lưu lượng pod giả lập xuyên namespace (cố gắng truy cập ingress bất hợp pháp); xác minh đồng bộ secret qua ESO (`ADR-011`).
* **Tiêu chí Thành công**: Các NetworkPolicy mặc định từ chối (default-deny) chặn thành công giao tiếp pod không hợp lệ; 0 secret dạng plain-text bị lộ (`SEC-001`).

### 4. Hiệu năng & Đo đạc Tải Cơ sở (Performance & Baseline Profiling)
* **Phạm vi**: Độ trễ microservice (P95/P99), thời gian phản hồi truy vấn cơ sở dữ liệu.
* **Phương pháp Kiểm thử**: Benchmark endpoint API giả lập bằng Locust / k6.
* **Tiêu chí Thành công**: Độ trễ P95 < 200ms tại ranh giới ALB dưới lưu lượng cơ sở.

### 5. Kiểm thử Tải & Dung lượng Bùng nổ (Load & Burst Capacity Testing)
* **Phạm vi**: Hiệu năng microservice dưới 200% thể tích lưu lượng bùng nổ đỉnh.
* **Phương pháp Kiểm thử**: Các bộ phát tải k6 phân tán giả lập 10,000 yêu cầu người dùng đồng thời.
* **Tiêu chí Thành công**: 0 lỗi HTTP 500; kích hoạt tự động mở rộng HPA động thành công (`NFR-002`).

### 6. Kiểm thử Mở rộng Động (Mở rộng Pod & Node)
* **Phạm vi**: Mở rộng pod qua HPA/KEDA và mở rộng node qua engine Karpenter JIT (`ADR-005`).
* **Phương pháp Kiểm thử**: Bơm nhu cầu pod unschedulable; đo thời gian khởi tạo node.
* **Tiêu chí Thành công**: Karpenter cấp phát EC2 worker node mới trong vòng < 60 giây (`NFR-002`).

### 7. Kiểm thử Sẵn sàng Cao & Failover Multi-AZ (HA & Multi-AZ Failover Testing)
* **Phạm vi**: Giả lập EC2 worker node bị crash và sự cố mạng Availability Zone.
* **Phương pháp Kiểm thử**: Chấm dứt node bằng Chaos Mesh; giả lập hố đen mạng AZ bằng AWS fault injection simulator (FIS).
* **Tiêu chí Thành công**: Các pod được tái lập lịch sang các AZs còn sống; failover cơ sở dữ liệu MySQL hoàn thành trong < 60 giây mà không mất dữ liệu (`NFR-001`).

### 8. Kiểm thử Sao lưu & Khôi phục PITR (Backup & PITR Restoration Testing)
* **Phạm vi**: Khôi phục cơ sở dữ liệu Point-in-Time Recovery (PITR) và khôi phục trạng thái Velero Kubernetes.
* **Phương pháp Kiểm thử**: Xóa thử bảng cơ sở dữ liệu hàng tháng và khôi phục tự động sang các subnet Test cô lập (`ADR-013`).
* **Tiêu chí Thành công**: 100% bản ghi cơ sở dữ liệu được khôi phục về chính xác mốc thời gian trước khi xóa (`RSK-DAT-002`).

### 9. Diễn tập Khôi phục Thảm họa Vùng (Disaster Recovery Regional Failover Drills)
* **Phạm vi**: Giả lập sự cố mất hoàn toàn một Region AWS chính.
* **Phương pháp Kiểm thử**: Chuyển đổi failover Cloudflare DNS / GTM sang cluster Pilot Light / Standby ở vùng thứ hai (`ADR-014`).
* **Tiêu chí Thành công**: Thỏa mãn các mục tiêu RTO và RPO; nền tảng ở vùng thứ hai vận hành tốt.

### 10. Kiểm thử Pipeline CI/CD & Rollback Tự động (CI/CD Pipeline & Automated Rollback Testing)
* **Phạm vi**: Tự động hóa triển khai GitLab → Jenkins → Ansible → ArgoCD và rollback theo kiểm tra sức khỏe.
* **Phương pháp Kiểm thử**: Triển khai một ảnh container ứng dụng bị lỗi; xác minh rollback tự động (`ADR-004`).
* **Tiêu chí Thành công**: ArgoCD tự động khôi phục tag ảnh về commit ổn định trước đó trong vòng 10 phút.

### 11. Xác minh Chi phí FinOps & Tagging (FinOps Cost & Tagging Validation)
* **Phạm vi**: Xác minh tính tuân thủ tag tài nguyên AWS và độ chính xác phân bổ Cost Explorer.
* **Phương pháp Kiểm thử**: Quét tự động bằng quy tắc AWS Config cho các tài nguyên chưa được gắn tag (`CST-002`).
* **Tiêu chí Thành công**: 100% tài nguyên AWS được cấp phát chứa các tag `CostCenter` và `Environment` hợp lệ.
