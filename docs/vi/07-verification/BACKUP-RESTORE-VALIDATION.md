# Kế hoạch Xác minh Sao lưu & Khôi phục (Backup & Restore Validation Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Quy cách Xác minh Sao lưu & Khôi phục Theo mốc Thời gian (PITR)** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng yêu cầu [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md) và [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md):
* Việc sao lưu vận hành độc lập với Sẵn sàng Cao (HA) để bảo vệ khỏi rủi ro hư hỏng dữ liệu hoặc vô tình xóa dữ liệu.
* Các đợt diễn tập khôi phục hàng tháng xác minh khôi phục point-in-time sang các subnet Test cô lập.
* **Không kết quả kiểm thử nào được đánh dấu trước là đã đạt (passed)**. Tất cả các mục xác minh sao lưu hiện duy trì trạng thái `Pending`.

---

## 2. Ma trận Xác minh Sao lưu & Khôi phục

| Miền Trạng thái Mục tiêu | Yêu cầu / ADR Quản trị | Chính sách Vòng đời Sao lưu | Tiêu chí Đạt Khôi phục Mục tiêu | Mã Bằng chứng Bắt buộc | Chủ sở hữu Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Cơ sở Dữ liệu Quan hệ (MySQL)**| [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Snapshots tự động hàng ngày + continuous transaction log PITR 30 ngày | 100% bản ghi DB được khôi phục về chính xác timestamp | `EVD-DB-001` | Trưởng nhóm DBA | `Pending` |
| **2. Cơ sở Dữ liệu Tài liệu (MongoDB)** | [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Volume snapshots hàng ngày + lưu trữ liên tục oplog (PITR 30 ngày) | Replay oplog hoàn chỉnh tới giây khôi phục mục tiêu | `EVD-DB-002` | Trưởng nhóm DBA | `Pending` |
| **3. In-Memory Cache (Redis)** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | RDB snapshots hàng ngày xuất sang S3 bucket mã hóa | Khôi phục RDB snapshot Redis sang node mới (< 15m) | `EVD-CACHE-002` | Trưởng nhóm Hạ tầng | `Pending` |
| **4. Trạng thái Cluster EKS Kubernetes**| [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Sao lưu Velero hàng ngày cho CRDs, manifests, và volume snapshots PVC | Khôi phục toàn bộ manifest cluster & volume sang Test EKS | `EVD-BK-001` | Trưởng nhóm SRE | `Pending` |
| **5. Bản sao Sao lưu Xuyên Tài khoản** | [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | Copy tự động sang Tài khoản AWS Security cô lập | Xác minh bản sao sao lưu bất biến trong Account Security | `EVD-BK-002` | Trưởng nhóm Bảo mật Đám mây | `Pending` |
| **6. Bảo vệ chống Ransomware** | [`SEC-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md) | AWS Backup Vault Lock ở chế độ Compliance | 0 ghi đè chính sách lưu trữ hoặc xóa trước hạn | `EVD-BK-003` | Trưởng nhóm Bảo mật Đám mây | `Pending` |

---

## 3. Quy trình Kiểm thử Khôi phục

### Kiểm thử BAK-01 — Diễn tập Khôi phục theo mốc Thời gian (PITR) MySQL
* **Quy trình**:
  1. Chèn các bản ghi kiểm thử có timestamp vào cơ sở dữ liệu MySQL `DataBlue-Prod-Account`.
  2. Giả lập hành động vô tình xóa bảng cơ sở dữ liệu tại mốc thời gian `T_drop`.
  3. Khởi tạo khôi phục AWS RDS PITR tới timestamp mục tiêu `T_drop - 1 giây` vào subnet database VPC Test cô lập.
* **Tiêu chí Đạt**: 100% bản ghi dữ liệu trước `T_drop` được khôi phục thành công; xác minh zero giao dịch bị mất (`EVD-DB-001`).

### Kiểm thử BAK-02 — Diễn tập Khôi phục Trạng thái Cluster bằng Velero
* **Quy trình**: Thực thi `velero restore create --from-backup prod-daily-backup` vào một EKS Test cluster rỗng.
* **Tiêu chí Đạt**: 100% Kubernetes Deployment manifests, ConfigMaps, Secrets, và EBS PersistentVolumeClaims được khôi phục về trạng thái `Ready` (`EVD-BK-001`).
