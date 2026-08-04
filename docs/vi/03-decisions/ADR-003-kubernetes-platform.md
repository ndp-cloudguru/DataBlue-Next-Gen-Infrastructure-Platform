# ADR-003 — Engine Nền tảng Kubernetes (Kubernetes Platform Engine)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Đám mây, Trưởng nhóm DevOps
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-OPS-001` (Gánh nặng chi phí bảo trì vận hành control plane)
* **Giả định Liên quan**: [`ASM-003`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 6
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Nền tảng yêu cầu một container runtime Kubernetes cấp doanh nghiệp để điều phối ~40 microservices (`FUN-001`). Chúng ta phải lựa chọn triển khai control plane Kubernetes bên dưới và engine quản lý.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Độ Bền vững & Sẵn sàng của Control Plane**: Đảm bảo thời gian uptime control plane multi-AZ mà không cần quản lý thủ công etcd quorum (`NFR-001`).
2. **Tích hợp Dịch vụ AWS Native**: Tích hợp mượt mà với AWS IAM (IRSA), VPC CNI, AWS KMS và AWS ALB Ingress Controllers (`SEC-001`).
3. **Chi phí Bảo trì Vận hành**: Giảm thiểu chi phí quản trị đội ngũ cho việc vá lỗi control plane, nâng cấp OS master node và sao lưu/khôi phục.

---

## Các Hạn chế
* Hạ tầng phải được cấp phát natively trên AWS.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Kubernetes Tự Quản lý trên EC2 (kOps / kubeadm)
* **Mô tả**: Triển khai và quản lý các etcd node và API server master EC2 instance thủ công bằng script kOps hoặc kubeadm.
* **Ưu điểm**: Không tốn phí EKS control plane (tiết kiệm $0.10/giờ); toàn quyền truy cập các cờ API server Kubernetes.
* **Nhược điểm**: Độ phức tạp vận hành cực cao; đội ngũ phải quản lý sao lưu etcd quorum, vá lỗi OS, failover control plane multi-AZ và nâng cấp thủ công.
* **Tác động Bảo mật**: Rủi ro cao về các lỗ hổng control plane chưa được vá hoặc cấu hình mã hóa etcd sai.
* **Tác động Sẵn sàng**: Trung bình-Yếu trừ khi có đội SRE chuyên trách giám sát etcd quorum 24/7.
* **Tác động Mở rộng**: Đòi hỏi thay đổi kích thước master node thủ công khi cluster tải cao.
* **Tác động Vận hành**: Chi phí nhân công và gánh nặng vận hành liên tục rất lớn (`RSK-OPS-001`).
* **Tác động Chi phí**: Tiết kiệm ~$73/tháng phí control plane, nhưng làm tăng đáng kể chi phí nhân công SRE.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Đội ngũ SRE chuyên trách có chuyên môn sâu về control plane Kubernetes.
* **Rủi ro**: `RSK-OPS-001` (Gánh nặng vận hành nghiêm trọng và rủi ro hỏng etcd).

### Phương án 2: Amazon EKS (Managed Kubernetes Control Plane của AWS)
* **Mô tả**: Sử dụng Amazon EKS, nơi AWS quản lý độ sẵn sàng control plane, mã hóa etcd và mở rộng master node multi-AZ.
* **Ưu điểm**: Uptime control plane 99.95% cam kết theo SLA; quản lý etcd tự động; tích hợp native AWS IAM IRSA; năng lực managed node group.
* **Nhược điểm**: Tốn phí control plane $0.10/giờ ($73/tháng) mỗi cluster; AWS kiểm soát mốc thời gian nâng cấp phiên bản master node.
* **Tác động Bảo mật**: Rất tốt. Mã hóa etcd AWS KMS tích hợp và xác thực IAM OIDC (`SEC-001`).
* **Tác động Sẵn sàng**: Rất tốt. Control plane active-active Multi-AZ được cấp phát tự động.
* **Tác động Mở rộng**: Rất tốt. Control plane tự động mở rộng dựa trên lưu lượng yêu cầu API.
* **Tác động Vận hành**: Chi phí quản lý control plane tối thiểu.
* **Tác động Chi phí**: Phí $0.10/giờ dự đoán được mỗi cluster.
* **Phụ thuộc Nhà cung cấp**: Trung bình (Tích hợp AWS EKS native).
* **Độ phức tạp Di chuyển**: Thấp (Tương thích API Kubernetes upstream tiêu chuẩn).
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: Chu kỳ hết hạn phiên bản AWS (yêu cầu nâng cấp cluster hàng năm).

### Phương án 3: Nền tảng Managed Thay thế (Red Hat OpenShift trên AWS - ROSA)
* **Mô tả**: Nền tảng Red Hat OpenShift managed chạy trên hạ tầng AWS.
* **Ưu điểm**: Developer portal doanh nghiệp, tích hợp sẵn pipeline CI/CD và service mesh tích hợp sẵn out-of-the-box.
* **Nhược điểm**: Chi phí bản quyền cao hơn đáng kể (phi dịch vụ Red Hat subscription); định hướng nền tảng cứng nhắc.
* **Tác động Bảo mật**: Năng lực tuân thủ doanh nghiệp mạnh mẽ.
* **Tác động Sẵn sàng**: Cao. Do AWS và Red Hat quản lý.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Yêu cầu kiến thức vận hành chuyên biệt OpenShift.
* **Tác động Chi phí**: Chi phí bản quyền rất cao so với EKS tiêu chuẩn.
* **Phụ thuộc Nhà cung cấp**: Cao (Phụ thuộc nền tảng Red Hat OpenShift).
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Hợp đồng Red Hat subscription.
* **Rủi ro**: Chi phí bản quyền phần mềm cao.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: Tự quản lý trên EC2 | Phương án 2: Amazon EKS | Phương án 3: Red Hat ROSA |
| :--- | :--- | :--- | :--- |
| **Control Plane HA & SLA** | Yếu | **Mạnh** | **Mạnh** |
| **Tích hợp AWS IAM / VPC** | Trung bình | **Mạnh** | Trung bình |
| **Sự Đơn giản Vận hành** | Yếu | **Mạnh** | Trung bình |
| **Hiệu quả Chi phí** | Trung bình (Nhân công cao) | **Mạnh** | Yếu (Bản quyền cao) |
| **Khả năng Đảo ngược** | Khó | **Dễ dàng Đảo ngược** | Khó |

---

## Quyết định Đề xuất
**Phương án 2: Amazon EKS (AWS Managed Kubernetes Control Plane)**.

---

## Lý do Lựa chọn
Amazon EKS loại bỏ hoàn toàn gánh nặng quản lý control plane (`RSK-OPS-001`), mang lại tích hợp native AWS IAM/VPC, và cung cấp tính tương thích API Kubernetes tiêu chuẩn với chi phí bằng một phần nhỏ so với các giải pháp độc quyền.

---

## Hệ quả
* **Tích cực**: SLA control plane 99.95%; nhân công bảo trì SRE tối thiểu; tích hợp IRSA native.
* **Tiêu cực**: Phí control plane $0.10/giờ mỗi cluster môi trường.
* **Trách nhiệm Vận hành Mới**: Theo dõi chu kỳ hỗ trợ phiên bản AWS EKS và lên kế hoạch nâng cấp cluster hàng năm.
* **Rủi ro Mới**: Hết hạn phiên bản API EKS.
* **Hệ quả Chi phí**: ~$146/tháng cho phí quản lý control plane Test + Prod.

---

## Bằng chứng Xác minh
* Tài liệu SLA dịch vụ AWS EKS và kiểm toán tích hợp IAM OIDC IRSA.

## Điều kiện Nghiệm thu
* Phê duyệt từ Hội đồng Kiến trúc Doanh nghiệp.

## Triggers Xem xét lại
* Thay đổi mô hình chi phí control plane EKS hoặc yêu cầu linh hoạt đa đám mây (multi-cloud).

## Tác động Triển khai
* Control plane EKS được cấp phát qua module Terraform EKS tiêu chuẩn trong Phase 3.
