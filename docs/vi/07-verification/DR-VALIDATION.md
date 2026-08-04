# Kế hoạch Xác minh Khôi phục Thảm họa (Disaster Recovery Validation Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Quy cách Xác minh Failover Vùng trong Khôi phục Thảm họa (DR)** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng yêu cầu [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md) và [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md):
* Các đợt diễn tập DR giả lập sự cố mất hoàn toàn thảm họa của Region AWS chính (ví dụ: `us-east-1`).
* **Không kết quả kiểm thử nào được đánh dấu trước là đã đạt (passed)**. Tất cả các mục xác minh DR hiện duy trì trạng thái `Deferred` chờ ký duyệt chính thức các SLAs RTO/RPO từ phía nghiệp vụ (`OPEN-003`).

---

## 2. Ma trận Xác minh Khôi phục Thảm họa (DR)

| Phạm vi Thành phần DR | Yêu cầu / ADR Quản trị | SLA Khôi phục Mục tiêu | Tiêu chí Đạt Xác minh Mục tiêu | Mã Bằng chứng Bắt buộc | Chủ sở hữu Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Thời gian Khôi phục Mục tiêu (RTO)** | [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **RTO < 4 Giờ** | Nền tảng ở vùng thứ hai online hoàn toàn & phục vụ lưu lượng trong < 4h | `EVD-DR-001` | Kiến trúc sư Trưởng Đám mây | `Deferred` (Chờ SLA) |
| **2. Mốc Thời gian Khôi phục Mục tiêu (RPO)** | [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **RPO < 15 Phút** | Khoảng thời gian mất dữ liệu xuyên vùng được xác minh < 15 phút | `EVD-DR-001` | Trưởng nhóm DBA / Trưởng nhóm SRE | `Deferred` (Chờ SLA) |
| **3. Cloudflare Global Traffic Manager (GTM) / DNS Failover** | [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **DNS Failover < 5 Phút** | Kiểm tra sức khỏe Cloudflare DNS/GTM kích hoạt chuyển đổi CNAME sang ALB thứ hai | `EVD-DR-002` | Trưởng nhóm Mạng | `Deferred` (Chờ SLA) |
| **4. Sẵn sàng của Cluster EKS Thứ hai**| [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **Pilot Light / Standby** | Control plane của EKS cluster hoạt động tại vùng AWS thứ hai | `EVD-DR-003` | Trưởng nhóm Hạ tầng | `Deferred` (Chờ SLA) |
| **5. Bản sao Cơ sở Dữ liệu Xuyên Vùng** | [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md) | **Cross-Region Snapshot** | Nhân bản read-replica / snapshot đa vùng hoạt động | `EVD-DR-004` | Trưởng nhóm DBA | `Deferred` (Chờ SLA) |

---

## 3. Giao thức Kiểm thử Failover Khôi phục Thảm họa Vùng

### Kiểm thử DR-01 — Giả lập Sự cố Vùng & Failover
* **Quy trình**:
  1. Kích hoạt giả lập sự cố hoàn toàn của vùng AWS chính (`us-east-1`) trong Cloudflare DNS / GTM.
  2. Thăng cấp read-replica cơ sở dữ liệu xuyên vùng ở vùng thứ hai (`us-west-2`) thành Primary.
  3. Mở rộng các nhóm EC2 worker node EKS Pilot Light ở vùng thứ hai qua Terraform / Karpenter.
  4. Đồng bộ triển khai các microservice bằng engine GitOps ArgoCD tại vùng thứ hai.
* **Tiêu chí Đạt**:
  1. Nền tảng ở vùng thứ hai đạt 100% trạng thái vận hành trong vòng < 4 giờ (RTO).
  2. Khoảng lệch mất dữ liệu giữa tầng cơ sở dữ liệu chính và thứ hai được xác minh < 15 phút (RPO).
  3. Log bằng chứng được đính kèm dưới dạng `EVD-DR-001`.
