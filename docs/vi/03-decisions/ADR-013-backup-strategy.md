# ADR-013 — Chiến lược Sao lưu (Backup Strategy)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Hạ tầng, Quản trị viên Cơ sở Dữ liệu (DBA)
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Đội ngũ Bảo mật
* **Yêu cầu Liên quan**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-DAT-002` (Lỗi khôi phục sao lưu chưa kiểm thử), `RSK-SEC-003` (Ransomware phá hủy bản sao lưu)
* **Giả định Liên quan**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 12
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `NFR-003` bắt buộc có các cơ chế khôi phục để bảo vệ trạng thái ứng dụng khỏi xóa nhầm, hư hỏng dữ liệu hoặc tấn công ransomware. Khả năng Sẵn sàng Cao (Dư thừa Multi-AZ) bảo vệ khỏi sự cố phần cứng, nhưng **không bảo vệ khỏi hư hỏng dữ liệu hoặc xóa nhầm**. Chúng ta phải thiết lập chiến lược sao lưu point-in-time được tách biệt rõ ràng khỏi HA và Khôi phục Thảm họa (DR).

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Khôi phục Point-in-Time (PITR)**: Khả năng khôi phục cơ sở dữ liệu quan hệ và tài liệu về bất kỳ giây cụ thể nào trong cửa sổ 30 ngày (`NFR-003`).
2. **Chụp Trạng thái Kubernetes Cluster**: Sao lưu các custom resource definitions (CRDs), secrets, configmaps và persistent volumes (`OPS-002`).
3. **Bảo vệ Chống Ransomware Xuyên Tài khoản**: Nhân bản các snapshot sao lưu bất biến sang Tài khoản AWS Security cô lập (`SEC-002`).

---

## Các Hạn chế
* Sao lưu phải chạy tự động mà không gây giảm hiệu năng cơ sở dữ liệu.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Chỉ Sao lưu Native Dịch vụ (Script Dump DB Riêng lẻ)
* **Mô tả**: Chạy các script cron tùy chỉnh (`mysqldump`, `mongodump`) thực thi bên trong pod hoặc node EC2, ghi các file dump ra đĩa cục bộ hoặc S3.
* **Ưu điểm**: Cấu hình script đơn giản.
* **Nhược điểm**: Ảnh hưởng hiệu năng CPU/memory nặng trong khi dump; thiếu độ chính xác khôi phục point-in-time; rất dễ gặp lỗi script và bỏ sót trạng thái Kubernetes.
* **Tác động Bảo mật**: Yếu. File dump không mã hóa trên đĩa cục bộ.
* **Tác động Sẵn sàng**: Yếu. Rủi ro khóa bảng (table lock) cao trong khi dump.
* **Tác động Mở rộng**: Kém. Thất bại với các cơ sở dữ liệu dung lượng nhiều GB.
* **Tác động Vận hành**: Gánh nặng bảo trì script cao.
* **Tác động Chi phí**: Phí dịch vụ AWS thấp.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: `RSK-DAT-002` (Snapshot cơ sở dữ liệu không đồng nhất và bản sao lưu bị hỏng).

### Phương án 2: Dịch vụ AWS Backup Thuần túy
* **Mô tả**: Sử dụng các chính sách AWS Backup tập trung để chụp snapshot AWS RDS, EBS volumes và S3 buckets.
* **Ưu điểm**: Dashboard AWS backup tập trung duy nhất; tự động hóa AWS Backup Vault Lock (chống ransomware); hỗ trợ copy xuyên tài khoản.
* **Nhược điểm**: Không tự động chụp được các manifest ứng dụng Kubernetes, CRDs hoặc volume claims statefulset nội bộ cluster.
* **Tác động Bảo mật**: Rất tốt. Mã hóa KMS, AWS Backup Vault Lock.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Chi phí quản lý tối thiểu.
* **Tác động Chi phí**: Giá lưu trữ snapshot AWS tiêu chuẩn.
* **Phụ thuộc Nhà cung cấp**: Trung bình (Định dạng AWS Backup).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Thiết lập AWS Backup Vault.
* **Rủi ro**: Bỏ sót trạng thái vận hành Kubernetes khi dựng lại toàn bộ cluster.

### Phương án 3: Mô hình Sao lưu Lai (Native DB PITR + Velero EKS State Backups)
* **Mô tả**: Một kiến trúc sao lưu hai phần toàn diện:
  1. **Tầng Cơ sở Dữ liệu**: Snapshot tự động managed hàng ngày với nhật ký giao dịch liên tục cho phép Khôi phục Point-in-Time (PITR) 30 ngày cho MySQL, MongoDB và Redis (`NFR-003`).
  2. **Tầng Kubernetes**: Operator Velero Backup cài đặt trong EKS, lên lịch sao lưu hàng ngày các CRD cluster, namespaces, secrets và EBS volume snapshots trực tiếp về S3 buckets mã hóa (`OPS-002`).
  3. **Cô lập Ransomware Xuyên Tài khoản**: Tự động nhân bản S3 backup snapshots sang Tài khoản AWS Security cô lập (`SEC-002`).
* **Ưu điểm**: Bao phủ 100% trạng thái cơ sở dữ liệu và manifest vận hành Kubernetes; 0 khóa bảng cơ sở dữ liệu; bảo vệ bất biến chống ransomware; khôi phục toàn bộ cluster nhanh chóng.
* **Nhược điểm**: Yêu cầu duy trì các CRD Operator Velero và chính sách IAM S3 bucket.
* **Tác động Bảo mật**: Mạnh nhất. Mã hóa KMS at rest + bảo vệ S3 bucket bất biến xuyên tài khoản (`SEC-002`).
* **Tác động Sẵn sàng**: Cao. Sao lưu chạy ngầm tự động.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Bảo trì vận hành thấp.
* **Tác động Chi phí**: Hiệu quả chi phí rất cao (các quy tắc vòng đời S3 tối ưu chi phí lưu trữ snapshot).
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Thiết lập Velero S3 bucket và IAM IRSA.
* **Rủi ro**: `RSK-DAT-002` (Không thực hiện chạy thử khôi phục sao lưu định kỳ).

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: Script Dump | Phương án 2: AWS Backup Thuần | Phương án 3: Lai (Native DB + Velero) |
| :--- | :--- | :--- | :--- |
| **Khôi phục Point-in-Time (PITR)** | Yếu | Mạnh | **Mạnh (Chính xác tới từng giây)** |
| **Chụp Trạng thái K8s (`OPS-002`)** | Không có | Yếu | **Mạnh (Velero CRDs)** |
| **Cô lập Ransomware (`SEC-002`)** | Yếu | Mạnh | **Mạnh (S3 Copy Xuyên Account)** |
| **Độ Tin cậy Vận hành** | Thấp | Cao | **Cao** |
| **Khả năng Đảo ngược** | Khó | Có thể đảo ngược | **Dễ dàng Đảo ngược** |

---

## Quyết định Đề xuất
**Phương án 3: Mô hình Sao lưu Lai** (Snapshot Cơ sở Dữ liệu Native với PITR + Velero EKS State Backups về S3).

---

## Lý do Lựa chọn
Phương án 3 cung cấp khả năng khôi phục tuyệt đối cho cả trạng thái giao dịch cơ sở dữ liệu và các manifest cấu hình Kubernetes (`NFR-003`), đồng thời thực thi cô lập bản sao S3 bất biến xuyên tài khoản để đảm bảo khôi phục ngay cả khi một tài khoản môi trường bị chiếm quyền.

---

## Hệ quả
* **Tích cực**: Khôi phục cơ sở dữ liệu PITR 30 ngày hoàn chỉnh; tự động khôi phục trạng thái EKS cluster qua Velero; bản sao lưu chống ransomware xuyên tài khoản.
* **Tiêu cực**: Yêu cầu cấu hình chính sách nhân bản S3 bucket Velero.
* **Trách nhiệm Vận hành Mới**: Thực hiện chạy thử khôi phục sao lưu tự động hàng quý (`RSK-DAT-002`).
* **Rủi ro Mới**: `RSK-DAT-002` (Quy trình khôi phục sao lưu chưa được xác minh).
* **Hệ quả Chi phí**: Phí lưu trữ S3 snapshot nhỏ.

---

## Bằng chứng Xác minh
* Chạy thử khôi phục cluster Velero và xác minh khôi phục snapshot point-in-time cơ sở dữ liệu.

## Điều kiện Nghiệm thu
* Phê duyệt từ Trưởng nhóm Hạ tầng và Đội ngũ Bảo mật.

## Triggers Xem xét lại
* Bắt buộc tuân thủ quy định lưu trữ sao lưu băng từ offline nhiều năm.

## Tác động Triển khai
* Manifest Velero Helm chart và các chính sách vòng đời AWS Backup được cấp phát trong Phase 3.
