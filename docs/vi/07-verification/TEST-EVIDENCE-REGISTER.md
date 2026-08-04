# Sổ ký Bằng chứng Kiểm thử (Test Evidence Register): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Sổ ký Bằng chứng Kiểm thử Master** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng các quy tắc quản trị Stage 5:
* **Không cổng nghiệm thu nào (`CỔNG-01` đến `CỔNG-10`) được cấp phép nếu thiếu bằng chứng đã xác minh được đính kèm vào sổ ký này**.
* Mỗi mục bằng chứng đòi hỏi đường dẫn artifact vật lý, timestamp thực thi, mã băm SHA-256, kỹ sư chịu trách nhiệm, và trạng thái xác minh.

---

## 2. Danh mục Bằng chứng Kiểm thử Master

| Mã Bằng chứng | Cổng Nghiệm thu Mục tiêu | Mô tả Artifact Bằng chứng | Định dạng Artifact / Loại File Yêu cầu | Kỹ sư Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`EVD-EVD-001`** | [`CỔNG-01`](../04-planning/ACCEPTANCE-GATES.md) | Báo cáo Đo đạc Bằng chứng Tải (CPU/RAM/IOPS) | `profiling_report.pdf` | Kiến trúc sư Trưởng Đám mây | `Pending` |
| **`EVD-ENV-001`** | [`CỔNG-04`](../04-planning/ACCEPTANCE-GATES.md) | Kiểm toán Cô lập Tài khoản & VPC AWS Landing Zone | `landing_zone_audit.json` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **`EVD-K8S-001`** | [`CỔNG-05`](../04-planning/ACCEPTANCE-GATES.md) | Đầu ra Kiểm thử Tuân thủ Sonobuoy EKS Kubernetes | `sonobuoy_results.tar.gz` | Kiến trúc sư Hạ tầng | `Pending` |
| **`EVD-ING-001`** | [`CỔNG-05`](../04-planning/ACCEPTANCE-GATES.md) | Quét SSL Labs Hạng A Chứng chỉ Ingress TLS | `ssl_labs_scan.pdf` | Kỹ sư DevOps | `Pending` |
| **`EVD-SEC-001`** | [`CỔNG-05`](../04-planning/ACCEPTANCE-GATES.md) | Báo cáo Quét Lỗ hổng Container Trivy (0 Critical) | `trivy_scan_report.json` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **`EVD-SEC-002`** | [`CỔNG-05`](../04-planning/ACCEPTANCE-GATES.md) | Kiểm toán Đặc quyền Tối thiểu IAM Access Analyzer (0 `*`) | `iam_policy_audit.json` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **`EVD-SCL-001`** | [`CỔNG-06`](../04-planning/ACCEPTANCE-GATES.md) | Benchmark Tự động Mở rộng Node Karpenter (< 60s) | `karpenter_scale_metrics.csv` | Trưởng nhóm SRE | `Pending` |
| **`EVD-PRF-001`** | [`CỔNG-06`](../04-planning/ACCEPTANCE-GATES.md) | Báo cáo Kiểm thử Tải Thử nghiệm Kỹ thuật (Locust/k6) | `k6_benchmark_report.html` | Trưởng nhóm Hiệu năng | `Pending` |
| **`EVD-CAB-001`** | [`CỔNG-07`](../04-planning/ACCEPTANCE-GATES.md) | Ticket Ủy quyền Đã ký từ Hội đồng CAB | `cab_release_ticket.pdf` | Nhà tài trợ Dự án | `Pending` |
| **`EVD-DB-001`** | [`CỔNG-08`](../04-planning/ACCEPTANCE-GATES.md) | Xác minh Khôi phục Snapshot PITR 30 Ngày RDS MySQL | `rds_pitr_restore_log.txt` | Trưởng nhóm DBA | `Pending` |
| **`EVD-HA-001`** | [`CỔNG-08`](../04-planning/ACCEPTANCE-GATES.md) | Log Diễn tập Chaos Mesh Sự cố AZ & Chấm dứt Node | `chaos_failover_log.txt` | Trưởng nhóm SRE | `Pending` |
| **`EVD-DR-001`** | [`CỔNG-08`](../04-planning/ACCEPTANCE-GATES.md) | Log Kiểm thử SLA RTO/RPO Diễn tập DR Vùng | `dr_failover_drill.log` | Kiến trúc sư Trưởng Đám mây | `Pending` |
| **`EVD-WAV-001`** | [`CỔNG-09`](../04-planning/ACCEPTANCE-GATES.md) | Chứng nhận Ký duyệt Làn Di chuyển Ứng dụng | `wave_1_5_signoff.pdf` | Trưởng nhóm Di chuyển | `Pending` |
| **`EVD-CST-001`** | [`CỔNG-10`](../04-planning/ACCEPTANCE-GATES.md) | Báo cáo Tuân thủ Tag Tài nguyên FinOps (100%) | `aws_cost_tag_audit.csv` | Trưởng nhóm FinOps | `Pending` |
| **`EVD-OPS-001`** | [`CỔNG-10`](../04-planning/ACCEPTANCE-GATES.md) | Biên bản Nghiệm thu Bàn giao Vận hành Hỗ trợ Đã ký | `handover_certificate.pdf` | Trưởng nhóm Vận hành | `Pending` |

---

## 3. Lưu trữ Bằng chứng & Quản trị Tính Toàn vẹn

1. **Vị trí Lưu trữ**: Tất cả các file bằng chứng kiểm thử raw bắt buộc phải được tải lên S3 Evidence Vault mã hóa chuyên trách (`s3://databue-test-evidence-vault/`) trong Tài khoản Security.
2. **Chính sách Bất biến**: Bật Object Lock trên bucket bằng chứng để ngăn ngừa xóa hoặc sửa đổi bằng chứng xác minh.
3. **Ràng buộc Truy xuất**: Các Mã Bằng chứng (`EVD-xxx`) bắt buộc phải được tham chiếu chéo bên trong [`REQUIREMENT-TRACEABILITY-MATRIX.md`](REQUIREMENT-TRACEABILITY-MATRIX.md).
