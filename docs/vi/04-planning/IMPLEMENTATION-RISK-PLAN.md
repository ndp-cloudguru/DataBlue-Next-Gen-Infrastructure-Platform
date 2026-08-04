# Kế hoạch Rủi ro Triển khai (Implementation Risk Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này ánh xạ tất cả các rủi ro đã được nhận diện (`RISK-REGISTER.md`) trực tiếp tới 11 giai đoạn triển khai của **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Nó làm nổi bật các **Vấn đề Chặn Production (Production Blockers)** quan trọng bắt buộc phải được giải quyết hoàn toàn trước khi bước vào Giai đoạn 7 (Xây dựng Nền tảng Production).

---

## 2. Ánh xạ Rủi ro Triển khai theo từng Giai đoạn

| Giai đoạn | Tên Giai đoạn | Rủi ro Liên quan Chính | Biện pháp Giảm thiểu & Cổng Kiểm soát | Chặn Production? |
| :--- | :--- | :--- | :--- | :--- |
| **Giai đoạn 0** | **Thu thập Bằng chứng** | `RSK-UNC-001`, `RSK-UNC-002`, `RSK-DAT-001`, `RSK-UNC-003` | Đo đạc tải, kiểm toán truy vấn DocumentDB, ký duyệt BCP ([`CỔNG-01`](ACCEPTANCE-GATES.md)). | **CÓ (CHẶN NGHIÊM TRỌNG)** |
| **Giai đoạn 1** | **Nền tảng AWS** | `RSK-SEC-003`, `RSK-CST-001` | Cô lập Landing Zone Đa Tài khoản, mã hóa KMS ([`CỔNG-04`](ACCEPTANCE-GATES.md)). | **CÓ** |
| **Giai đoạn 2** | **Xây dựng Nền tảng Test** | `RSK-OPS-001`, `RSK-SCL-001` | EKS Test cluster chuyên trách, liên kết định danh IRSA ([`CỔNG-05`](ACCEPTANCE-GATES.md)). | Không |
| **Giai đoạn 3** | **Dịch vụ Nền tảng Dùng chung**| `RSK-SEC-001`, `RSK-CST-002`, `RSK-DAT-002` | ArgoCD GitOps, đồng bộ secret ESO, vòng đời S3 Fluent Bit. | Không |
| **Giai đoạn 4** | **Tích hợp CI/CD** | `RSK-ARC-001`, `RSK-SEC-001` | Mô hình Phủ Phân tầng Lai, chính sách 0 secret tĩnh trong Git. | Không |
| **Giai đoạn 5** | **Triển khai Middleware** | `RSK-OPS-001`, `RSK-ARC-002` | Failover cơ sở dữ liệu Multi-AZ, Nacos Raft cluster, PITR 30 ngày. | **CÓ** |
| **Giai đoạn 6** | **Thử nghiệm Kỹ thuật** | `RSK-SCL-001`, `RSK-CST-001` | Kiểm thử tải giả lập, mở rộng node Karpenter < 60s ([`CỔNG-06`](ACCEPTANCE-GATES.md)). | **CÓ** |
| **Giai đoạn 7** | **Xây dựng Production** | `RSK-SEC-003`, `RSK-DAT-002` | Ký duyệt từ CAB ([`CỔNG-07`](ACCEPTANCE-GATES.md)), AWS Backup Vault Lock. | **CÓ** |
| **Giai đoạn 8** | **Các Làn Di chuyển** | `RSK-DEL-001`, `RSK-SEC-001` | Tiêu chí đầu vào/đầu ra của làn, rollback ArgoCD tự động ([`CỔNG-09`](ACCEPTANCE-GATES.md)). | Không |
| **Giai đoạn 9** | **Sẵn sàng Production** | `RSK-AVL-001`, `RSK-DAT-002` | Chaos Mesh node crashes, giả lập sự cố AZ, diễn tập DR ([`CỔNG-08`](ACCEPTANCE-GATES.md)). | **CÓ** |
| **Giai đoạn 10**| **Bàn giao Vận hành** | `RSK-OPS-001`, `RSK-OPS-002` | Bàn giao runbook, đào tạo SRE, bàn giao quyền truy cập ([`CỔNG-10`](ACCEPTANCE-GATES.md)). | Không |

---

## 3. Tóm tắt các Vấn đề Chặn Production

Trước khi sự phê duyệt của CAB (`CỔNG-07`) được cấp để xây dựng `DataBlue-Prod-Account`, 5 rủi ro sau đây bắt buộc phải được giải quyết:
1. `RSK-UNC-001` (Hồ sơ định kích thước microservice được thu thập và xác minh).
2. `RSK-DAT-001` (Hoàn thành kiểm toán tương thích DocumentDB).
3. `RSK-UNC-003` (Ký duyệt chính thức bằng văn bản các mục tiêu RTO/RPO SLA nghiệp vụ).
4. `RSK-SEC-003` (Xác minh cô lập Đa Tài khoản mà không có VPC peering xuyên tài khoản).
5. `RSK-SCL-001` (Benchmark tải Thử nghiệm Kỹ thuật được chấp nhận tại `CỔNG-06`).
