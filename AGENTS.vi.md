# Quy tắc & Hướng dẫn Vận hành dành cho AI Agent: Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

> **Language / Ngôn ngữ**: [English](AGENTS.md) | [Tiếng Việt](AGENTS.vi.md)

---

## 1. Tổng quan & Triết lý Quản trị

Tài liệu này quy định các quy tắc vận hành bắt buộc, điều kiện biên và quy trình làm việc cho tất cả các AI Agent hoạt động trong repository **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

Tất cả các AI Agent hoạt động trong dự án này bắt buộc phải tuân thủ nghiêm ngặt các nguyên tắc **Quản trị Hướng Kiến trúc (Architecture-First Governance)**:

> **Kiến trúc, Đặc tả, Khả năng Truy xuất Nguồn gốc và Sự Phê duyệt của Con người Bắt buộc Phải Có Trước khi Sinh Mã Nguồn.**

---

## 2. Các Chỉ thị Vận hành & Kiến trúc Cốt lõi

1. **Tầng Vành đai Edge**: Luôn chỉ định **Cloudflare Enterprise Edge (Cloudflare DNS, CDN, WAF & Global Traffic Manager GTM)** làm điểm bảo mật và định tuyến chính đứng trước AWS Internet Gateways và Application Load Balancers (ALB).
2. **Đội ngũ Quản trị Vận hành Hợp nhất**: Các vai trò Cloud Platform SRE, DevOps Engineering và Cloud Security được hợp nhất thành một đội ngũ duy nhất: **Cloud Platform SRE & DevSecOps Team**.
3. **Bốn Kịch bản Tài chính Chuẩn hóa**:
   - **Kịch bản 1 (Test Tiêu chuẩn Non-Prod)**: `~$1,600 – $2,400 / tháng` (2-AZ, 70% Spot / 30% On-Demand, Karpenter Autoscaling, Stack CI/CD riêng).
   - **Kịch bản 2 (Production Cơ sở)**: `~$4,200 – $6,100 / tháng` (3-AZ, Savings Plans 3 năm, RDS MySQL Managed, OpenSearch 2-Node).
   - **Kịch bản 3 (Production Sẵn sàng Cao Nâng cao)**: `~$7,200 – $10,500 / tháng` (3-AZ, Transit Gateway, Amazon Aurora MySQL 3 Replicas, Redis Sharded Cluster 6-Node, OpenSearch 4-Node).
   - **Kịch bản 4 (Production Khôi phục Thảm họa Xuyên Vùng)**: `~$10,000 – $14,800 / tháng` (Primary `us-east-1` + Standby Pilot Light `us-west-2`, Cloudflare GTM Failover với SLA RTO < 4h, RPO < 15m).
4. **Tiêu chuẩn Sơ đồ Mermaid**: Tất cả các sơ đồ kiến trúc phải được quản lý dưới dạng file `.mmd` độc lập tại `diagrams/src/` và biên dịch ra SVG (`diagrams/svg/`) và PNG (`diagrams/png/`) bằng script `python3 diagrams/render.py`. Sơ đồ Lộ trình Triển khai (`Phase 0` đến `Phase 10`) phải sử dụng chiều dọc (`graph TD`).
5. **Cấm các Thao tác Phá hủy Đám mây**: AI Agent **TUYỆT ĐỐI KHÔNG ĐƯỢC** thực thi các lệnh đám mây mang tính phá hủy (như `terraform destroy`, `aws ec2 terminate-instances`, `aws s3 rb`, `aws eks delete-cluster`) nếu không có văn bản phê duyệt trực tiếp của con người trong prompt context.

---

## 3. Hành vi Được phép & Bị cấm theo Giai đoạn Dự án

| Giai đoạn Dự án | Hành vi Được phép | Hành vi Bị cấm | Cổng Phê duyệt Bắt buộc |
| :--- | :--- | :--- | :--- |
| **Phase 0: Yêu cầu Cơ sở & Đặc tả** | • Tái cấu trúc & chuẩn hóa yêu cầu<br>• Soạn thảo đặc tả & danh mục đăng ký<br>• Xây dựng khung mô hình chi phí & sơ đồ | • Viết mô-đun Terraform / Helm hoàn chỉnh<br>• Thực thi các lệnh cấp phát AWS thực tế | Con người phê duyệt bộ sản phẩm đặc tả Phase 0 |
| **Phase 1: Kiến trúc & ADRs** | • Soạn thảo Nhật ký Quyết định Kiến trúc (ADR)<br>• Vẽ sơ đồ kiến trúc logic & mạng<br>• Phân tích đánh đổi kỹ thuật | • Triển khai tài nguyên AWS thực tế<br>• Cố định cấu hình nếu chưa có số liệu | Con người phê duyệt các bản ADR & sơ đồ kiến trúc |
| **Phase 2: Thiết kế Chi tiết & Chi phí** | • Tính toán mô hình chi phí tham số (Kịch bản 1–4)<br>• Định nghĩa subnetting, IAM policies & security groups | • Cấp phát môi trường đám mây thực tế<br>• Chạy trực tiếp script IaC lên AWS | Con người phê duyệt mô hình chi phí & đặc tả chi tiết |
| **Phase 3: Thử nghiệm IaC & Manifests** | • Viết mã nguồn IaC Terraform / OpenTofu<br>• Tạo Helm charts & K8s manifests<br>• Chạy `terraform plan` / dry-runs Sandbox | • Chạy `terraform apply` trên Production<br>• Sửa đổi state trực tiếp không qua GitOps | Con người phê duyệt kết quả `terraform plan` |
| **Phase 4: Chuyển giao Prod & DR** | • Chạy thử nghiệm tải & giả lập failover DR<br>• Tạo báo cáo tuân thủ & runbooks | • Xóa tài nguyên mang tính phá hủy<br>• Tắt logging bảo mật hoặc nhật ký kiểm toán | Phê duyệt chính thức từ Hội đồng Phê duyệt Thay đổi (CAB) |

---

## 4. Quy ước & Mã Định danh Yêu cầu

Tất cả các sản phẩm dự án phải tuân thủ nghiêm ngặt định dạng ID chuẩn:
* **Yêu cầu Kinh doanh**: `BUS-001`, `BUS-002`, ...
* **Yêu cầu Chức năng**: `FUN-001`, `FUN-002`, ...
* **Yêu cầu Phi Chức năng**: `NFR-001`, `NFR-002`, ...
* **Yêu cầu Bảo mật**: `SEC-001`, `SEC-002`, ...
* **Yêu cầu Vận hành & Quan sát**: `OPS-001`, `OPS-002`, ...
* **Yêu cầu Quản lý Chi phí**: `CST-001`, `CST-002`, ...
* **Nhật ký Quyết định Kiến trúc**: `ADR-001`, `ADR-002`, ...
* **Work Packages & Gates**: `WP-001`–`WP-020`, `GATE-01`–`GATE-10`.

---

## 5. Giao thức Phê duyệt của Con người (Human-in-the-Loop)

AI Agent phải dừng thực thi và yêu cầu con người xem xét phê duyệt bất cứ khi nào:
1. Có sự mơ hồ ảnh hưởng lớn đến chi phí đám mây AWS hoặc ranh giới bảo mật.
2. Một quyết định kiến trúc đòi hỏi cam kết không thể đảo ngược.
3. Bất kỳ lệnh hoặc script nào có thể làm thay đổi trạng thái hạ tầng AWS thực tế.
