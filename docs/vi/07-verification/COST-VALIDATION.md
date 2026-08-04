# Kế hoạch Xác minh & Quản trị Chi phí FinOps (FinOps Cost Governance & Validation Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Kế hoạch Xác minh Định kích thước & Quản trị Chi phí FinOps** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Theo đúng các yêu cầu [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), và [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md):
* Chi tiêu AWS thực tế được kiểm toán hàng tháng so với Mô hình Chi phí Tham số ([`COST-MODEL.md`](../05-cost/COST-MODEL.md)) và các Kịch bản A đến E ([`COST-SCENARIOS.md`](../05-cost/COST-SCENARIOS.md)).
* **Không kết quả kiểm thử nào được đánh dấu trước là đã đạt (passed)**. Tất cả các mục xác minh chi phí hiện duy trì trạng thái `Pending`.

---

## 2. Ma trận Xác minh Quản trị Chi phí

| Miền Quản trị FinOps | Yêu cầu / Chính sách Quản trị | Phạm vi Kiểm toán Xác minh | Tiêu chí Đạt Chấp nhận Mục tiêu | Mã Bằng chứng Bắt buộc | Chủ sở hữu Chịu trách nhiệm | Trạng thái Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Tuân thủ Tag Tài nguyên** | [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md) | Kiểm toán Quy tắc Chính sách Tagging AWS Config | **100%** tài nguyên AWS được cấp phát chứa các tag hợp lệ | `EVD-CST-001` | Trưởng nhóm FinOps | `Pending` |
| **2. Sai lệch Chi tiêu so với Mô hình** | [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-MODEL.md`](../05-cost/COST-MODEL.md) | Hóa đơn AWS Cost Explorer hàng tháng so với Kịch bản cơ sở | Sai lệch chi tiêu AWS hàng tháng trong khoảng **±15%** Mô hình Chi phí | `EVD-CST-002` | Trưởng nhóm FinOps | `Pending` |
| **3. Co giảm Quy mô Non-Prod Tự động**| [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | Lên lịch co giảm quy mô các worker node EKS Test | Giảm 70% số node ngoài giờ làm việc (ban đêm/cuối tuần) | `EVD-CST-003` | Trưởng nhóm SRE | `Pending` |
| **4. Tỷ lệ Sử dụng Spot Instance** | [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | Tỷ lệ kết hợp loại giá worker node EKS Test | **≥ 70%** EC2 Spot instances trong môi trường Test | `EVD-CST-004` | Trưởng nhóm Hạ tầng | `Pending` |
| **5. Độ Bao phủ Savings Plans** | [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | Compute Savings Plans áp dụng cho Prod EKS baseline | **≥ 80%** EC2 Production baseline được bao phủ bởi Savings Plan | `EVD-CST-005` | Trưởng nhóm FinOps | `Pending` |
| **6. Vòng đời Lưu trữ Log** | [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-012`](../03-decisions/ADR-012-observability.md) | Quy tắc Vòng đời S3 Bucket cho log Fluent Bit | Log tự động chuyển từ S3 Standard sang Glacier sau 30 ngày | `EVD-OPS-002` | Trưởng nhóm Vận hành | `Pending` |
| **7. Kích hoạt Cảnh báo AWS Budget**| [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`COST-OPTIMIZATION-PLAN.md`](../05-cost/COST-OPTIMIZATION-PLAN.md) | Tích hợp cảnh báo AWS Budgets & Anomaly Detector | Cảnh báo Slack/Email tự động tại ngưỡng 85% ngân sách | `EVD-CST-006` | Trưởng nhóm FinOps | `Pending` |

---

## 3. Giao thức Kiểm toán Xác minh Chi phí

### Kiểm thử CST-01 — Kiểm toán Tuân thủ Tag Tài nguyên AWS
* **Quy trình**: Chạy quy tắc AWS Config `required-tags` trên tất cả các Tài khoản AWS (`DataBlue-Test`, `DataBlue-Prod`, `Shared-Services`, `Security`).
* **Các Tag Key Bắt buộc**: `Environment`, `BusinessSystem`, `CostCenter`, `Owner`.
* **Tiêu chí Đạt**: `0` tài nguyên AWS không tuân thủ chưa được gắn tag (`EVD-CST-001`).

### Kiểm thử CST-02 — Kiểm toán Sai lệch Mô hình Chi tiêu Hàng tháng
* **Quy trình**: Trích xuất hóa đơn hàng tháng từ AWS Cost Explorer và so sánh với Kịch bản C Production Baseline (~$3,800/tháng).
* **Tiêu chí Đạt**: Tổng chi tiêu AWS duy trì trong ngưỡng ±15%; bằng chứng đính kèm dưới dạng `EVD-CST-002`.
