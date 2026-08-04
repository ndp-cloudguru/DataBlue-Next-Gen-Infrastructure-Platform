# Kế hoạch Sẵn sàng Hỗ trợ (Support Readiness Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định các yêu cầu bắt buộc, danh mục kiểm tra (checklists), và các giao thức bàn giao để chuyển giao **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`) từ giai đoạn triển khai dự án sang **Vận hành Hỗ trợ** dài hạn.

Được quản trị bởi [`CỔNG-10`](../04-planning/ACCEPTANCE-GATES.md) (Nghiệm thu Bàn giao).

---

## 2. Checklist Chuyển giao Hỗ trợ Vận hành

| Danh mục | Mục Xác minh Sẵn sàng | Vai trò Chịu trách nhiệm | Tiêu chí Đạt | Trạng thái |
| :--- | :--- | :--- | :--- | :--- |
| **Runbooks** | Runbooks Vận hành được viết cho 100% các cảnh báo PagerDuty | Trưởng nhóm DevOps | Quy trình khắc phục từng bước được xác minh | Chờ xử lý |
| **Observability**| 100% các metric microservice được hiển thị trên Grafana | Trưởng nhóm SRE | Dashboard tập trung hoạt động | Chờ xử lý |
| **Logging** | Tìm kiếm log hoạt động trong OpenSearch có lưu trữ S3 Glacier | Trưởng nhóm Vận hành | Xác minh tìm kiếm 7 ngày + xuất S3 | Chờ xử lý |
| **Sao lưu** | Xác minh khôi phục tự động Velero & Database PITR | Trưởng nhóm DBA | Thực thi kiểm thử khôi phục hàng tháng ([`CỔNG-08`](../04-planning/ACCEPTANCE-GATES.md)) | Chờ xử lý |
| **Diễn tập DR** | Diễn tập failover DR xuyên vùng thực thi thành công | Kiến trúc sư Đám mây | Thỏa mãn SLAs RTO & RPO tại vùng thứ hai | Chờ xử lý |
| **Bảo mật** | 100% các chính sách IAM được xác minh đặc quyền tối thiểu (0 `*`) | Trưởng nhóm Bảo mật | Vượt qua kiểm toán IAM Access Analyzer | Chờ xử lý |
| **Đào tạo** | 100% các kỹ sư SRE trực ban được đào tạo về nền tảng | Trưởng nhóm SRE | Ký duyệt hoàn thành đào tạo | Chờ xử lý |
| **Quyền truy cập** | Quyền truy cập Production được cấp qua IAM Identity Center SSO | Trưởng nhóm Bảo mật | 0 static SSH/AWS keys | Chờ xử lý |
| **FinOps** | Tag phân bổ chi phí được xác minh trên 100% tài nguyên | Trưởng nhóm FinOps | Xác minh phân rã AWS Cost Explorer | Chờ xử lý |

---

## 3. Ký duyệt Bàn giao Vận hành

Sau khi hoàn thành 100% các mục checklist trên, bàn giao chính thức diễn ra thông qua việc ký **Biên bản Nghiệm thu Bàn giao Vận hành**:

```markdown
### Biên bản Nghiệm thu Bàn giao Vận hành
* **Tên Nền tảng**: DataBlue Next-Gen Infrastructure Platform (`datablue-nextgen-infra-platform`)
* **Trưởng nhóm Triển khai Dự án**: `[Chữ ký & Ngày]`
* **Trưởng nhóm Vận hành / SRE Doanh nghiệp**: `[Chữ ký & Ngày]`
* **Nhà tài trợ Dự án**: `[Chữ ký & Ngày]`
```
