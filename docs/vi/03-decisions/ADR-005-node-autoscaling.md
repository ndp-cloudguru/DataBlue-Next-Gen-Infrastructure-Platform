# ADR-005 — Engine Mở rộng Node Tự động (Node Autoscaling Engine)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Đám mây, Kỹ sư Hạ tầng
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Đội ngũ FinOps
* **Yêu cầu Liên quan**: [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-SCL-001` (Độ trễ cấp phát node mới chậm), `RSK-CST-001` (Chi phí tự động mở rộng node không kiểm soát)
* **Giả định Liên quan**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 10
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `NFR-002` quy định mở rộng hạ tầng cấp độ node linh hoạt cho EKS cluster lưu trữ ~40 microservices. Các chỉ số định kích thước hiện chưa có sẵn (`OPEN-001`). Chúng ta phải lựa chọn một engine tự động mở rộng node khớp động dung lượng node với nhu cầu lập lịch pod mà không cần quản lý dung lượng thủ công.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Độ trễ Cấp phát Node**: Thời gian phản hồi nhanh để tăng dung lượng node khi có các pod chưa được lập lịch đang ở trạng thái pending (`NFR-002`).
2. **Tối ưu Chi phí & Rightsizing**: Lựa chọn chính xác kích thước và loại instance EC2 khớp với yêu cầu tài nguyên của pod đang chờ, tránh lãng phí dung lượng node (bin-packing waste) (`CST-001`).
3. **Sự Đơn giản Vận hành**: Loại bỏ chi phí quản lý định nghĩa thủ công các EC2 Auto Scaling Groups (ASGs) cho nhiều phân tầng CPU/RAM instance khác nhau.

---

## Các Hạn chế
* Phải chạy natively bên trong Amazon EKS.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Dung lượng Node EC2 Tĩnh (Không Tự động Mở rộng)
* **Mô tả**: Cấp phát một số lượng cố định EC2 instance mỗi node group dựa trên tải đỉnh ước tính.
* **Ưu điểm**: Cấu hình đơn giản; 0 lỗi logic tự động mở rộng.
* **Nhược điểm**: Lãng phí chi phí nghiêm trọng ngoài giờ cao điểm; rủi ro hỏng cluster do cạn kiệt bộ nhớ khi có đột biến lưu lượng ngoài dự kiến.
* **Tác động Bảo mật**: Trung tính.
* **Tác động Sẵn sàng**: Yếu khi đột biến lưu lượng.
* **Tác động Mở rộng**: Không có mở rộng node động (Vi phạm `NFR-002`).
* **Tác động Vận hành**: Yêu cầu can thiệp SRE thủ công để thay đổi số lượng instance EC2.
* **Tác động Chi phí**: Cực kỳ không hiệu quả (lãng phí AWS hàng tháng cao).
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: `RSK-SCL-001` (Lỗi pod không lập lịch được trong giờ cao điểm).

### Phương án 2: Managed Node Groups với Kubernetes Cluster Autoscaler (CAS)
* **Mô tả**: Sử dụng Kubernetes Cluster Autoscaler tiêu chuẩn, giám sát các pod pending và tăng dung lượng mong muốn của AWS Auto Scaling Groups (ASGs).
* **Ưu điểm**: Tiêu chuẩn Kubernetes lâu đời, đã được kiểm chứng; được hỗ trợ native bởi EKS Managed Node Groups.
* **Nhược điểm**: Phản hồi mở rộng chậm (~3-5 phút mỗi node); bị giới hạn bởi các loại instance trong ASG cấu hình sẵn; đóng gói bin-packing không hiệu quả cho nhiều kích thước pod đa dạng.
* **Tác động Bảo mật**: Tốt. Tích hợp với AWS IAM IRSA.
* **Tác động Sẵn sàng**: Trung bình-Cao.
* **Tác động Mở rộng**: Trung bình. Bị giới hạn trong các node pool ASG định nghĩa trước.
* **Tác động Vận hành**: Yêu cầu tạo và duy trì nhiều định nghĩa ASG cho các kích thước instance khác nhau.
* **Tác động Chi phí**: Hiệu quả đóng gói bin-packing chưa tối ưu.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Triển khai EKS Cluster Autoscaler.
* **Rủi ro**: Độ trễ cấp phát node chậm khi microservice mở rộng nhanh.

### Phương án 3: EKS Managed Node Groups + Karpenter (Engine Mở rộng Just-in-Time)
* **Mô tả**: Triển khai Karpenter, một engine tự động mở rộng node Kubernetes mã nguồn mở, hiệu năng cao do AWS phát triển, cấp phát trực tiếp các EC2 instance mà không cần ASGs bên dưới.
* **Ưu điểm**: Cấp phát nhanh (< 1 phút khởi tạo node); tự động chọn instance khớp chính xác yêu cầu của pod (`c6i`, `m6i`, `r6i`); tự động hợp nhất và rightsizing node (`CST-001`); điều phối linh hoạt Spot instance cho môi trường Test.
* **Nhược điểm**: Yêu cầu quản lý vòng đời controller Karpenter và cấu hình NodePool CRD.
* **Tác động Bảo mật**: Mạnh. Sử dụng AWS IAM Roles for Service Accounts (IRSA).
* **Tác động Sẵn sàng**: Rất tốt. Cấp phát node Multi-AZ dựa trên các ràng buộc topo.
* **Tác động Mở rộng**: Rất tốt. Cấp phát trực tiếp qua EC2 Fleet API bỏ qua các nút thắt ASG.
* **Tác động Vận hành**: Loại bỏ hoàn toàn bảo trì ASG; yêu cầu học cách dùng Karpenter NodePool CRD.
* **Tác động Chi phí**: Hiệu quả chi phí cao nhất (tiết kiệm 15-30% lãng phí tính toán qua bin-packing).
* **Phụ thuộc Nhà cung cấp**: Trung bình (Tối ưu hóa AWS EC2 Fleet).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Thiết lập EKS OIDC IRSA.
* **Rủi ro**: `RSK-UNC-001` (Tỷ lệ gián đoạn Spot instance chưa xác minh ở Test).

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: EC2 Tĩnh | Phương án 2: Cluster Autoscaler (CAS) | Phương án 3: Karpenter (JIT) |
| :--- | :--- | :--- | :--- |
| **Tốc độ Cấp phát Node** | Không | Trung bình (~3-5 phút) | **Nhanh (< 1 phút)** |
| **Hiệu quả Bin-Packing** | Yếu | Trung bình | **Mạnh** |
| **Chi phí Bảo trì ASG** | Thủ công | Cao (Nhiều ASGs) | **Không tốn Chi phí ASG** |
| **Tối ưu Chi phí (`CST-001`)** | Yếu | Trung bình | **Mạnh** |
| **Khả năng Đảo ngược** | Dễ dàng Đảo ngược | Có thể đảo ngược | **Có thể đảo ngược** |

---

## Quyết định Đề xuất
**Phương án 3: EKS Managed Node Groups + Karpenter (Engine Mở rộng Just-in-Time)**.

---

## Lý do Lựa chọn
Karpenter cung cấp tốc độ cấp phát vượt trội (`NFR-002`), tự động hóa lựa chọn instance động mà không tốn chi phí quản lý ASG, và mang lại hiệu quả tiết kiệm chi phí bin-packing FinOps tối ưu (`CST-001`), rất phù hợp trong khi các tham số kích thước tải chưa được chốt.

---

## Hệ quả
* **Tích cực**: Khởi tạo node nhanh chóng; tự động hợp nhất node; không quản lý ASG.
* **Tiêu cực**: Đội ngũ phải quản lý cấu hình Karpenter NodePool CRD.
* **Trách nhiệm Vận hành Mới**: Giám sát log controller Karpenter và hàng chờ ngắt kết nối instance.
* **Rủi ro Mới**: `RSK-CST-001` (Chi phí tự động mở rộng node không kiểm soát nếu pod bỏ qua giới hạn tài nguyên).
* **Hệ quả Chi phí**: Giảm chi tiêu tính toán EC2 hàng tháng qua rightsizing thông minh.

---

## Bằng chứng Xác minh
* Benchmark độ trễ cấp phát node Karpenter và kiểm thử hợp đồng tái lập lịch pod.

## Điều kiện Nghiệm thu
* Phê duyệt từ Trưởng nhóm Hạ tầng và Đội ngũ FinOps.

## Triggers Xem xét lại
* Controller Karpenter không tương thích với các phiên bản API EKS tương lai.

## Tác động Triển khai
* Manifest Karpenter Helm chart và NodePool CRD được cấp phát trong Phase 3.
