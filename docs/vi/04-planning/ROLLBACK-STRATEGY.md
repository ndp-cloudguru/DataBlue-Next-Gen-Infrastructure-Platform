# Chiến lược & Quy trình Rollback: Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Quản trị & Các Nguyên tắc Rollback

Tài liệu này quy định **Chiến lược và Quy trình Rollback** bắt buộc trên chín tầng kỹ thuật của **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng [`AGENTS.md`](../../AGENTS.md) và [`PROJECT-CHARTER.md`](../00-governance/PROJECT-CHARTER.md):
* **Mọi thay đổi production bắt buộc phải có quy trình rollback tự động hoặc được tài liệu hóa**.
* **Không hành động phá hủy nào được phép lập kế hoạch nếu thiếu xác minh sao lưu và quy trình khôi phục (rollback)**.

---

## 2. Quy cách Rollback theo từng Tầng Kỹ thuật

### 1. Rollback Thay đổi Hạ tầng (Terraform / AWS Foundation)
* **Kích hoạt (Trigger)**: Lỗi `terraform apply` hoặc cảnh báo xóa tài nguyên ngoài dự kiến trong khi thực thi (`WP-002`, `WP-004`).
* **Quy trình Rollback**: Revert Git commit trong repository Terraform; thực thi `terraform apply` trỏ về phiên bản file S3 state trước đó; khôi phục tài nguyên đã xóa qua AWS Backup snapshot nếu cần.
* **Thời gian Khôi phục Tối đa**: < 30 phút.

### 2. Rollback Nâng cấp EKS Control Plane
* **Kích hoạt (Trigger)**: Suy giảm hiệu năng API server EKS control plane hoặc bất tương thích plugin sau khi nâng cấp (`ADR-003`).
* **Quy trình Rollback**: Nâng cấp managed AWS EKS control plane **không thể hạ cấp (downgrade) về phiên bản minor trước đó**. Giảm thiểu rủi ro đòi hỏi triển khai một EKS cluster thứ hai song song ở phiên bản minor trước đó qua Terraform, khôi phục trạng thái cluster qua Velero, và chuyển đổi định tuyến DNS ingress.
* **Thời gian Khôi phục Tối đa**: < 2 giờ.

### 3. Rollback Triển khai Node & Tự động Mở rộng (Karpenter)
* **Kích hoạt (Trigger)**: EC2 AMI node pool mới gây ra crash loop cho pod hoặc lỗi CNI mạng (`ADR-005`).
* **Quy trình Rollback**: Cập nhật CRD `EC2NodeClass` của Karpenter trong Git trỏ về AMI ID trước đó; thực thi `karpenter.sh/do-not-disrupt: false`; Karpenter thực hiện cordon và drain các node bị lỗi, thay thế chúng bằng các instance AMI ổn định.
* **Thời gian Khôi phục Tối đa**: < 15 phút.

### 4. Rollback Release Ứng dụng (Microservices)
* **Kích hoạt (Trigger)**: Tỷ lệ lỗi HTTP 5xx > 0.01% hoặc pod microservice bị crash loop sau triển khai (`WP-017`).
* **Quy trình Rollback**: Automated ArgoCD / Ansible rollback. ArgoCD reverts manifest image tag to previous stable Git commit SHA (`ecr.aws/microservice:previous-sha`); rolling update restores healthy pods (`CICD-DELIVERY-PLAN.md`).
* **Thời gian Khôi phục Tối đa**: < 5 phút.

### 5. Rollback Di chuyển Cơ sở Dữ liệu (MySQL / MongoDB)
* **Kích hoạt (Trigger)**: Lỗi script di chuyển schema hoặc hư hỏng dữ liệu ứng dụng sau khi di chuyển (`WP-011`).
* **Quy trình Rollback**: Thực thi script SQL rollback Liquibase / Flyway chiều ngược. Nếu dữ liệu bị hư hỏng, khởi tạo Amazon RDS Point-in-Time Recovery (PITR) để khôi phục cơ sở dữ liệu về chính xác mốc thời gian trước khi thực thi di chuyển (`ADR-013`).
* **Thời gian Khôi phục Tối đa**: < 30 phút (khôi phục PITR).

### 6. Rollback Nâng cấp Middleware (Redis / RabbitMQ / Nacos)
* **Kích hoạt (Trigger)**: Lỗi phân tách stateful broker hoặc Nacos Raft quorum không ổn định sau nâng cấp (`WP-012`, `WP-013`).
* **Quy trình Rollback**: Khôi phục tag ảnh Helm release qua ArgoCD; khôi phục trạng thái volume từ Velero S3 snapshot nếu phiên bản schema bị biến đổi.
* **Thời gian Khôi phục Tối đa**: < 20 phút.

### 7. Rollback Chính sách IAM & Bảo mật
* **Kích hoạt (Trigger)**: Cập nhật chính sách IAM IRSA quá thắt chặt chặn các lượt gọi AWS API của pod (`WP-003`).
* **Quy trình Rollback**: Revert module HCL chính sách IAM trong Terraform; thực thi `terraform apply`; token EKS IRSA OIDC của pod tự động được làm mới.
* **Thời gian Khôi phục Tối đa**: < 10 phút.

### 8. Rollback Kiến trúc Mạng & Security Group
* **Kích hoạt (Trigger)**: Cấu hình sai NetworkPolicy hoặc Security Group làm mất traffic microservice xuyên AZ (`WP-004`).
* **Quy trình Rollback**: Revert module HCL Security Group hoặc manifest YAML NetworkPolicy trong repository GitOps; ArgoCD đồng bộ lại các quy tắc ingress/egress mặc định từ chối (default-deny) ban đầu.
* **Thời gian Khôi phục Tối đa**: < 5 phút.

### 9. Rollback Pipeline CI/CD & Runner
* **Kích hoạt (Trigger)**: Lỗi script triển khai Jenkins worker node hoặc Ansible playbook (`WP-010`).
* **Quy trình Rollback**: Revert commit Jenkinsfile / Ansible playbook trong repository Shared Services; ghim pipeline runner về phiên bản container image trước đó.
* **Thời gian Khôi phục Tối đa**: < 10 phút.
