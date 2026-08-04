# ADR-015 — Mô hình Hạ tầng dạng Mã (Infrastructure as Code Model)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Hạ tầng, Trưởng nhóm DevOps
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Đội ngũ Bảo mật
* **Yêu cầu Liên quan**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`AGENTS.md`](../../AGENTS.md), [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-DEL-001` (Độ phức tạp module IaC và tranh chấp lock state)
* **Giả định Liên quan**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 15
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `BUS-002` bắt buộc tự động hóa triển khai nền tảng. `AGENTS.md` bắt buộc hạ tầng bất biến theo phương pháp khai báo có quản lý phiên bản. Chúng ta phải lựa chọn ngôn ngữ Hạ tầng dạng Mã (IaC), kiến trúc quản lý state và mô hình cấp phát cho Nền tảng AWS Kubernetes.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Trạng thái Khai báo & Tính Bất biến**: 100% hạ tầng AWS (VPCs, subnets, IAM roles, EKS clusters, database instances) được cấp phát dạng khai báo qua code (`BUS-002`).
2. **Khả năng Tái sử dụng Mô-đun & Nguyên tắc DRY**: Tạo các module hạ tầng tái sử dụng cho các tài khoản Test và Production (`ADR-001`, `ADR-002`).
3. **Lock State & Khả năng Kiểm toán**: Khóa state từ xa qua S3 + DynamoDB để ngăn ngừa hư hỏng state khi thực thi đồng thời.

---

## Các Hạn chế
* Phải sinh mã nguồn IaC sạch, có quản lý phiên bản trong quá trình tạo prototype Phase 3.

---

## Các Phương án Đang Đánh giá

### Phương án 1: AWS CloudFormation
* **Mô tả**: Sử dụng các template CloudFormation JSON/YAML native của AWS.
* **Ưu điểm**: Dịch vụ AWS native; không yêu cầu quản lý bucket state từ xa.
* **Nhược điểm**: Cú pháp YAML dài dòng, cứng nhắc; rollback thực thi chậm; năng lực trừu tượng mô-đun yếu; thư viện module cộng đồng mã nguồn mở hạn chế.
* **Tác động Bảo mật**: Tốt. Tích hợp với AWS IAM.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Trung bình. Độ phức tạp nested stack.
* **Tác động Vận hành**: Gánh nặng bảo trì template cao.
* **Tác động Chi phí**: Zero chi phí công cụ.
* **Phụ thuộc Nhà cung cấp**: Cao (Cú pháp AWS CloudFormation).
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: Sai lệch CloudFormation stack và bị khóa khi rollback.

### Phương án 2: AWS Cloud Development Kit (AWS CDK trong TypeScript/Python)
* **Mô tả**: Soạn thảo hạ tầng sử dụng các ngôn ngữ lập trình mệnh lệnh (TypeScript/Python) được biên dịch ra CloudFormation.
* **Ưu điểm**: Cú pháp lập trình giàu biểu đạt; tái sử dụng construct hướng đối tượng.
* **Nhược điểm**: Mã nguồn mệnh lệnh che giấu trạng thái hạ tầng bên dưới; khó khăn cho các SRE không có nền tảng phát triển phần mềm; kiểm toán diff state phức tạp.
* **Tác động Bảo mật**: Tốt.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Yêu cầu cao về bảo trì ngôn ngữ lập trình.
* **Tác động Chi phí**: Zero chi phí công cụ.
* **Phụ thuộc Nhà cung cấp**: Cao (Các construct AWS CDK).
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Thành thạo ngôn ngữ TypeScript/Python.
* **Rủi ro**: Lỗi trừu tượng code tạo ra các diff CloudFormation ngoài dự kiến.

### Phương án 3: Modular Terraform / OpenTofu Thuần (Hạ tầng + K8s Manifests)
* **Mô tả**: Sử dụng HCL với Terraform / OpenTofu cho cả tài nguyên đám mây AWS và các release Kubernetes Helm nội bộ cluster qua Terraform Helm provider.
* **Ưu điểm**: Cú pháp HCL chuẩn công nghiệp; hệ sinh thái module mã nguồn mở khổng lồ; xem trước dry-run `terraform plan` rõ ràng (`AGENTS.md`).
* **Nhược điểm**: Quản lý tải công việc Kubernetes qua Terraform Helm provider có thể gây sai lệch state nếu lập trình viên cũng apply manifest bằng `kubectl`.
* **Tác động Bảo mật**: Rất tốt. Mã hóa S3 state từ xa + khóa DynamoDB locking.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Trung bình.
* **Tác động Chi phí**: Zero chi phí công cụ mã nguồn mở.
* **Phụ thuộc Nhà cung cấp**: Thấp (Cú pháp độc lập đám mây).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Backend remote state S3 + DynamoDB.
* **Rủi ro**: Tranh chấp lock file state Terraform.

### Phương án 4: Mô hình Lai (Terraform Mô-đun cho AWS Infra + Helm/Ansible/GitOps cho K8s Workloads)
* **Mô tả**: Phân tách rõ ràng trách nhiệm:
  1. **Terraform / OpenTofu**: Cấp phát hạ tầng đám mây AWS vật lý (VPCs, subnets, IAM IRSA roles, EKS control plane, node groups, KMS keys, database instances).
  2. **Helm / Ansible / ArgoCD**: Cấp phát các ứng dụng Kubernetes nội bộ cluster, Nacos, operators, ingress rules, và microservices (`BUS-002`, `FUN-004`).
* **Ưu điểm**: Ranh giới vận hành sạch sẽ; Terraform quản lý state hạ tầng đám mây; GitOps / Helm quản lý state ứng dụng nội bộ cluster mà không va chạm file state.
* **Nhược điểm**: Đòi hỏi quản lý hai tầng triển khai.
* **Tác động Bảo mật**: Mạnh nhất. Ranh giới thực thi IAM được giới hạn phạm vi.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Sự rõ ràng vận hành cao cho kỹ sư DevOps.
* **Tác động Chi phí**: Zero chi phí bản quyền công cụ.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Thiết lập S3 state bucket từ xa.
* **Rủi ro**: `RSK-DEL-001` (Triển khai không đồng bộ giữa cập nhật hạ tầng Terraform và triển khai GitOps).

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: CloudFormation | Phương án 2: AWS CDK | Phương án 3: Terraform Thuần | Phương án 4: Lai (Terraform Infra + GitOps K8s) |
| :--- | :--- | :--- | :--- | :--- |
| **Sự Rõ ràng Khai báo** | Trung bình | Yếu (Mệnh lệnh) | **Mạnh** | **Mạnh** |
| **Cô lập Ranh giới State** | Trung bình | Yếu | Trung bình | **Mạnh (Tách biệt)** |
| **Xem trước Dry-Run (`AGENTS.md`)** | Yếu | Trung bình | **Mạnh (`plan`)** | **Mạnh (`plan`)** |
| **Hệ sinh thái Module Mã nguồn mở**| Trung bình | Trung bình | **Mạnh** | **Mạnh** |
| **Khả năng Đảo ngược** | Khó | Có thể đảo ngược | Dễ dàng Đảo ngược | **Dễ dàng Đảo ngược** |

---

## Quyết định Đề xuất
**Phương án 4: Mô hình Lai** (Terraform / OpenTofu Mô-đun cho Hạ tầng AWS + Helm / Ansible / GitOps cho Tải công việc Kubernetes).

---

## Lý do Lựa chọn
Phương án 4 thiết lập ranh giới vận hành sạch sẽ tách biệt quản lý state hạ tầng đám mây khỏi logic triển khai ứng dụng, đảm bảo `terraform plan` cung cấp các đợt kiểm toán dry-run minh bạch mà không bị ô nhiễm file state từ các đợt triển khai pod ngắn hạn (`AGENTS.md`).

---

## Hệ quả
* **Tích cực**: Phân tách trách nhiệm sạch sẽ; đầu ra `terraform plan` minh bạch; kiến trúc mô-đun tái sử dụng được cho các tài khoản Test và Prod.
* **Tiêu cực**: Duy trì hai công cụ vận hành (Terraform cho AWS, Helm/GitOps cho K8s).
* **Trách nhiệm Vận hành Mới**: Quản lý các bucket S3 state backend từ xa và các bảng lock DynamoDB.
* **Rủi ro Mới**: `RSK-DEL-001` (Sai lệch phiên bản phụ thuộc module Terraform).
* **Hệ quả Chi phí**: Zero chi phí bản quyền phần mềm.

---

## Bằng chứng Xác minh
* Kiểm thử thực thi tự động `terraform fmt`, `tflint`, và `terraform plan` trong pipeline Shared Services CI/CD.

## Điều kiện Nghiệm thu
* Phê duyệt từ Trưởng nhóm Hạ tầng và Trưởng nhóm DevOps.

## Triggers Xem xét lại
* Đội ngũ chuẩn hóa trên một developer portal nội bộ doanh nghiệp đòi hỏi các driver IaC thay thế.

## Tác động Triển khai
* Mã nguồn Terraform mô-đun được soạn thảo trong Phase 3 tại thư mục `infrastructure/terraform/`.
