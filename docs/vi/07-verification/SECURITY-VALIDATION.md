# Kế hoạch Xác minh Bảo mật (Security Validation Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Quy cách Xác minh Bảo mật & Kế hoạch Kiểm toán** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng các yêu cầu [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), và [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md):
* Các kiểm soát bảo mật được kiểm toán trên 6 tầng bảo mật trước khi vào Production (`CỔNG-07`).
* **Không kết quả kiểm thử nào được đánh dấu trước là đã đạt (passed)**. Tất cả các mục xác minh bảo mật hiện duy trì trạng thái `Pending`.

---

## 2. Ma trận Xác minh Bảo mật 6 Tầng

| Tầng Bảo mật | Yêu cầu / ADR Quản trị | Phạm vi Kiểm toán Xác minh | Tiêu chí Đạt Chấp nhận Mục tiêu | Mã Bằng chứng Bắt buộc | Chủ sở hữu Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Định danh & Phạm vi IAM** | [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md) | Phạm vi role pod AWS IAM IRSA & quét IAM Access Analyzer | 0 quyền IAM dạng wildcard (`*`) trong các pod roles | `EVD-SEC-002` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **2. Lỗ hổng Container** | [`FUN-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md) | Quét Jenkins Trivy CVE trên các ảnh container | 0 lỗ hổng `CRITICAL` trong các ảnh container | `EVD-SEC-001` | Trưởng nhóm DevOps | `Pending` |
| **3. Cô lập Vành đai Mạng**| [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md) | VPC subnets, Security Groups & NetworkPolicies | 0 tuyến đường internet trực tiếp tới các subnet DB cô lập | `EVD-ENV-001` | Kiến trúc sư Mạng | `Pending` |
| **4. Quản lý Secrets** | [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md) | AWS Secrets Manager + External Secrets Operator (ESO) | 0 secret tĩnh dạng plain-text bị commit vào Git | `EVD-SEC-005` | Kỹ sư Bảo mật | `Pending` |
| **5. Mã hóa Dữ liệu at Rest** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md) | Cấu hình AWS KMS Customer-Managed Key (CMK) | 100% các volume EBS, DBs RDS, & S3 được mã hóa | `EVD-SEC-004` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **6. Mã hóa Dữ liệu in Transit** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md) | Mã hóa TLS 1.3 trên Ingress ALB & định tuyến mTLS pod | Đạt xếp hạng SSL Labs Hạng A trên các endpoint public | `EVD-ING-001` | Kỹ sư DevOps | `Pending` |

---

## 3. Quy trình Kiểm thử Xác minh Bảo mật

### Kiểm thử SEC-01 — Kiểm toán IAM IRSA Đặc quyền Tối thiểu
* **Quy trình**: Thực thi tự động IAM Access Analyzer trên tất cả các ARNs role IRSA được gắn vào các service account EKS.
* **Tiêu chí Đạt**: `0` chính sách chứa `Action: "*"` hoặc `Resource: "*"`.

### Kiểm thử SEC-02 — Kiểm toán Ingress Subnet Database Cô lập
* **Quy trình**: Thực thi dò mạng giả lập từ pod Test tới các Subnet Database trên các cổng không được ủy quyền.
* **Tiêu chí Đạt**: 100% nỗ lực kết nối không hợp lệ bị chặn bởi AWS Security Groups.

### Kiểm thử SEC-03 — Quét Lỗ hổng Ảnh Container
* **Quy trình**: Chạy quét lỗ hổng Trivy trong pipeline build container Jenkins (`FUN-003`).
* **Tiêu chí Đạt**: Jenkins build thành công khi và chỉ khi 0 CVEs mức `CRITICAL` được phát hiện.
