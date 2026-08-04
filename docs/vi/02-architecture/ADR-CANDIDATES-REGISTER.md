# Danh mục Ứng viên Quyết định Kiến trúc (ADR Candidates Register): Nền tảng AWS Kubernetes DataBlue

---

## 1. Tổng quan

Tài liệu này ghi lại tất cả các **Ứng viên Quyết định Kiến trúc (ADR Candidates)** được xác định trong Stage 2 (Định nghĩa Kiến trúc) của **Nền tảng AWS Kubernetes DataBlue** (`datablue-nextgen-infra-platform`).

Theo các quy tắc Stage 2:
* Các quyết định được đánh dấu tại đây là **các ứng viên tạm thời đang được đánh giá**.
* Không có ADR nào được chốt cho đến khi hoàn thành chấm điểm đánh đổi Phase 1 và có phê duyệt chính thức từ các bên liên quan.

---

## 2. Nhật ký Ứng viên ADR

| Mã Ứng viên | Tên Quyết định | Các Phương án Đang Đánh giá | Yêu cầu Ảnh hưởng | Góc nhìn Kiến trúc | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ADR-CAN-001` | **Mô hình Cô lập Môi trường** | **Phương án A**: Tài khoản AWS & EKS Cluster riêng biệt cho Test & Prod.<br>**Phương án B**: EKS Cluster Đa người dùng chung với cô lập Namespace. | `BUS-003`, `SEC-002`, `NFR-001` | Vật lý & Triển khai / Bảo mật | Proposed Baseline (Phương án A) |
| `ADR-CAN-002` | **Chiến lược Kiến trúc Middleware Lưu trạng thái** | **Phương án A**: Dịch vụ AWS Managed Services (RDS, ElastiCache, MSK/DocDB).<br>**Phương án B**: Middleware Operators Self-Hosted trên EKS (Bitnami/ECK/KubeBlocks). | `FUN-005`–`FUN-009`, `CST-001`, `OPS-001` | Logic / Vận hành / FinOps | Đang Đánh giá |
| `ADR-CAN-003` | **Lựa chọn Node Autoscaler Kubernetes** | **Phương án A**: Karpenter (Cấp phát node Just-in-Time).<br>**Phương án B**: Kubernetes Cluster Autoscaler Tiêu chuẩn (Auto Scaling Groups). | `NFR-002`, `CST-001`, `OPS-001` | Vận hành / Khả năng Mở rộng | Đang Đánh giá |
| `ADR-CAN-004` | **Kiến trúc Ingress Controller** | **Phương án A**: AWS Load Balancer Controller + NGINX Ingress Controller.<br>**Phương án B**: AWS VPC Lattice / Gateway API. | `BUS-001`, `SEC-003`, `OPS-001` | Edge & Ingress / Mạng | Đang Đánh giá |
| `ADR-CAN-005` | **Yêu cầu Service Mesh Nội bộ Cluster** | **Phương án A**: Istio / Linkerd Service Mesh cho mTLS và phân tách lưu lượng.<br>**Phương án B**: Native AWS VPC CNI + Kubernetes NetworkPolicies. | `SEC-003`, `OPS-001`, `NFR-002` | Bảo mật / Logic / Hiệu năng | Đang Đánh giá |
| `ADR-CAN-006` | **Topo Quản lý & Nạp Secrets** | **Phương án A**: AWS Secrets Manager + External Secrets Operator (ESO).<br>**Phương án B**: HashiCorp Vault Cluster + Vault Agent Injector. | `SEC-001`, `FUN-002`–`FUN-004`, `OPS-001` | Bảo mật & IAM | Đang Đánh giá |
| `ADR-CAN-007` | **Mô hình Failover Khôi phục Thảm họa** | **Phương án A**: Backup Lạnh Xuyên Vùng & Khôi phục theo Hạ tầng dạng Mã.<br>**Phương án B**: Cluster Pilot Light Xuyên Vùng / Warm Standby. | `NFR-003`, `CST-001` | Độ Bền vững / Vận hành / FinOps | Đang Đánh giá |
| `ADR-CAN-008` | **Lựa chọn Bảo mật Vành đai Edge & CDN/WAF** | **Phương án A**: Cloudflare Enterprise Edge (Cloudflare DNS, CDN, WAF & Global Traffic Manager GTM).<br>**Phương án B**: AWS Route 53 + AWS CloudFront + AWS WAF. | `SEC-002`, `SEC-003`, `NFR-001`, `NFR-003` | Edge & Bảo mật / Mạng / Độ Bền vững | Proposed Baseline (Phương án A) |
