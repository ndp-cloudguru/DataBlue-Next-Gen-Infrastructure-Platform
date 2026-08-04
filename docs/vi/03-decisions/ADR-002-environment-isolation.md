# ADR-002 — Mô hình Cô lập Môi trường (Environment Isolation Model)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Đám mây, Kỹ sư Bảo mật
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp
* **Yêu cầu Liên quan**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-SEC-003` (Bán kính ảnh hưởng sự cố cluster dùng chung), `RSK-SCL-001` (Cạnh tranh tài nguyên noisy neighbor)
* **Giả định Liên quan**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 4
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `BUS-003` bắt buộc cô lập môi trường nghiêm ngặt giữa môi trường Test và Production. Chúng ta phải quyết định cấp độ ranh giới cho cô lập runtime container (Kubernetes namespaces vs. cluster vật lý vs. ranh giới Tài khoản AWS).

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Bán kính Ảnh hưởng & Ranh giới Bảo mật**: Loại bỏ rủi ro mã nguồn non-production hoặc các pod bị chiếm quyền truy cập vào dữ liệu production (`SEC-002`).
2. **Bảo vệ Hiệu năng khỏi Noisy Neighbor**: Ngăn ngừa việc sử dụng vượt mức CPU/memory hoặc đột biến tải ở Test làm giảm hiệu năng tải công việc Production (`NFR-001`).
3. **Cô lập Rủi ro Nâng cấp**: Cho phép nâng cấp control plane EKS và OS worker node được xác minh kỹ lưỡng ở Test mà không gây rủi ro gián đoạn Production.

---

## Các Hạn chế
* Test và Production không được dùng chung hạ tầng trừ khi có ngoại lệ bảo mật chính thức được ủy quyền bằng văn bản.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Các Namespace Tách biệt trong Một EKS Cluster Đơn lẻ
* **Mô tả**: Lưu trữ tải công việc Test và Production trong cùng một EKS cluster dùng chung, phân tách bằng K8s namespaces và NetworkPolicies.
* **Ưu điểm**: Chi phí control plane cluster AWS thấp nhất (tiết kiệm $0.10/giờ); quản trị cluster đơn giản hơn.
* **Nhược điểm**: Bán kính ảnh hưởng kernel/node dùng chung; rủi ro cạn kiệt tài nguyên do noisy-neighbor cao; không có cô lập khi nâng cấp control-plane; quản lý RBAC phức tạp.
* **Tác động Bảo mật**: Yếu. Lỗ hổng thoát container (container escape) làm lộ tải công việc production.
* **Tác động Sẵn sàng**: Yếu. Sự cố etcd dùng chung và control plane failover ảnh hưởng cả hai môi trường.
* **Tác động Mở rộng**: Trung bình. Dùng chung giới hạn rate limit API cluster.
* **Tác động Vận hành**: Rủi ro cao trong quá trình bảo trì cluster.
* **Tác động Chi phí**: Tiết kiệm ~$73/tháng phí control plane.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Cao để tách ra sau này.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: `RSK-SEC-003` (Bán kính ảnh hưởng sự cố xuyên môi trường nghiêm trọng).

### Phương án 2: Các Cluster EKS Tách biệt trong Một Tài khoản AWS Đơn lẻ
* **Mô tả**: Cấp phát hai cluster EKS riêng biệt (Test Cluster, Prod Cluster) bên trong một Tài khoản AWS.
* **Ưu điểm**: Cô lập vật lý control plane Kubernetes và worker node.
* **Nhược điểm**: Dùng chung ranh giới tài khoản AWS IAM, rủi ro VPC routing dùng chung, giới hạn dịch vụ đám mây dùng chung.
* **Tác động Bảo mật**: Trung bình. Cô lập K8s tốt, nhưng rủi ro dùng chung IAM credential truy cập chéo.
* **Tác động Sẵn sàng**: Cao. Control plane K8s độc lập.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Trung bình.
* **Tác động Chi phí**: Thêm $0.10/giờ phí control plane EKS cho Test cluster.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Trung bình.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Thiết lập một Tài khoản AWS.
* **Rủi ro**: Vô tình tái sử dụng IAM credential xuyên môi trường.

### Phương án 3: Các Tài khoản AWS Tách biệt và Các Cluster EKS Tách biệt
* **Mô tả**: Lưu trữ Test trong `DataBlue-Test-Account` với EKS Cluster riêng, và Production trong `DataBlue-Prod-Account` với EKS Cluster riêng.
* **Ưu điểm**: Cô lập bảo mật và bán kính ảnh hưởng mạng tuyệt đối; 0 hạ tầng dùng chung; vòng đời nâng cấp cluster độc lập.
* **Nhược điểm**: Đòi hỏi quản lý các file state IaC đa tài khoản.
* **Tác động Bảo mật**: Mạnh nhất. Không có tuyến đường truy cập xuyên môi trường.
* **Tác động Sẵn sàng**: Mạnh nhất. Cô lập miền sự cố hoàn toàn.
* **Tác động Mở rộng**: Mạnh nhất. Hạn ngạch AWS độc lập hoàn toàn.
* **Tác động Vận hành**: Yêu cầu tự động hóa module IaC chuẩn hóa.
* **Tác động Chi phí**: Phí control plane EKS thêm ~$73/tháng (không đáng kể cho nền tảng doanh nghiệp).
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: AWS Landing Zone Đa Tài khoản (`ADR-001`).
* **Rủi ro**: Không có rủi ro nào được xác định về mặt cô lập.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: Chỉ Namespace | Phương án 2: Cluster trong 1 Account | Phương án 3: Account & Cluster Tách biệt |
| :--- | :--- | :--- | :--- |
| **Bán kính Ảnh hưởng Bảo mật** | Yếu | Trung bình | **Mạnh** |
| **Bảo vệ Noisy Neighbor** | Yếu | Mạnh | **Mạnh** |
| **An toàn Nâng cấp** | Yếu | Mạnh | **Mạnh** |
| **Rủi ro Vận hành** | Cao | Trung bình | **Thấp** |
| **Khả năng Đảo ngược** | Khó | Có thể đảo ngược | **Dễ dàng Đảo ngược** |

---

## Quyết định Đề xuất
**Phương án 3: Các Tài khoản AWS Tách biệt và Các Cluster EKS Tách biệt**.

---

## Lý do Lựa chọn
Phương án 3 đáp ứng nghiêm ngặt yêu cầu `BUS-003` và `SEC-002` bằng cách đảm bảo cô lập hoàn toàn về vật lý, logic và định danh giữa Test và Production.

---

## Hệ quả
* **Tích cực**: Không có rủi ro tải công việc Test ảnh hưởng đến hiệu năng hoặc bảo mật Production; kiểm thử nâng cấp cluster an toàn.
* **Tiêu cực**: Chi phí vận hành control plane EKS bổ sung ($0.10/giờ cho Test cluster).
* **Trách nhiệm Vận hành Mới**: Quản lý vòng đời hai cluster qua GitOps/IaC.
* **Rủi ro Mới**: Không.
* **Hệ quả Chi phí**: Bổ sung ~$73/tháng chi phí control plane.

---

## Bằng chứng Xác minh
* Kiểm toán ranh giới Tài khoản AWS và kiểm thử cô lập API endpoint EKS.

## Điều kiện Nghiệm thu
* Phê duyệt từ Trưởng nhóm Bảo mật Doanh nghiệp.

## Triggers Xem xét lại
* Chỉ đạo trực tiếp từ lãnh đạo khách hàng nhằm cắt giảm chi tiêu AWS non-production.

## Tác động Triển khai
* Các module cluster EKS riêng biệt được định nghĩa trong Terraform theo từng Tài khoản AWS.
