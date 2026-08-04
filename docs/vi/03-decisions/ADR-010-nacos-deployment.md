# ADR-010 — Chiến lược Triển khai Nacos (Nacos Deployment Strategy)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Ứng dụng, Trưởng nhóm DevOps
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp
* **Yêu cầu Liên quan**: [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-ARC-002` (Lỗi đồng bộ trạng thái Nacos cluster)
* **Giả định Liên quan**: [`ASM-001`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 3, Mục 6
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `FUN-009` quy định Nacos cho việc phát hiện dịch vụ (service discovery), quản lý cấu hình động (dynamic config), và kiểm tra sức khỏe trên ~40 microservices. Chúng ta phải quyết định triển khai Nacos trực tiếp bên trong EKS, trên các EC2 instance chuyên trách, hay thay thế bằng bộ công cụ khác.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Phát hiện Dịch vụ Inter-Service Độ trễ Thấp**: Tra cứu DNS / API thời gian thực cho các microservices đăng ký với Nacos (`FUN-009`).
2. **Sẵn sàng Cao & Trạng thái Quorum**: Đồng bộ Nacos cluster raft quorum Multi-AZ (`NFR-001`).
3. **Tuân thủ Yêu cầu**: Yêu cầu trực tiếp từ khách hàng về việc tương thích với Nacos mà không cần tái cấu trúc ứng dụng.

---

## Các Hạn chế
* Phải chạy chế độ Nacos 2.x+ cluster mode có hỗ trợ backend MySQL.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Nacos Cluster Triển khai trên EKS (Private Application Subnets)
* **Mô tả**: Triển khai Nacos dạng multi-replica StatefulSet bên trong EKS trên 3 AZs trong các Subnet Application Private, backed bởi tầng cơ sở dữ liệu MySQL cho lưu trữ cấu hình bền vững.
* **Ưu điểm**: Giao tiếp nội bộ cluster độ trễ sub-millisecond với các pod microservice; tự động hóa quản lý vòng đời pod qua Kubernetes Deployment/StatefulSet; không tốn chi phí EC2 instance riêng biệt.
* **Nhược điểm**: Đăng ký dịch vụ microservice phụ thuộc độ ổn định phân giải DNS của EKS cluster.
* **Tác động Bảo mật**: Mạnh. Cô lập bên trong private subnets; Kubernetes NetworkPolicies giới hạn ingress strictly cho các namespace microservice.
* **Tác động Sẵn sàng**: Cao. Nacos Raft cluster 3-node trải rộng trên 3 AZs.
* **Tác động Mở rộng**: Dễ dàng mở rộng pod replica.
* **Tác động Vận hành**: Bảo trì tải công việc Kubernetes tiêu chuẩn.
* **Tác động Chi phí**: Thấp (chạy trên tài nguyên worker node EKS sẵn có).
* **Phụ thuộc Nhà cung cấp**: Rất Thấp (Mã nguồn mở Nacos).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Sự sẵn sàng của cơ sở dữ liệu quan hệ MySQL (`FUN-005`).
* **Rủi ro**: `RSK-ARC-002` (Không ổn định khi bầu chọn Nacos Raft leader trong quá trình node failover).

### Phương án 2: EC2 Cluster Chuyên trách cho Nacos
* **Mô tả**: Triển khai Nacos trên một cluster EC2 3-node độc lập được quản lý qua Ansible.
* **Ưu điểm**: Cô lập control plane phát hiện dịch vụ khỏi các đợt lập lịch lại của EKS cluster.
* **Nhược điểm**: Phí instance AWS EC2 hàng tháng cao hơn; vá lỗi OS và bảo trì node thủ công.
* **Tác động Bảo mật**: Trung bình. Đòi hỏi quản lý security group VPC.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Thay đổi kích thước instance EC2 thủ công.
* **Tác động Vận hành**: Gánh nặng vận hành thủ công cao.
* **Tác động Chi phí**: Cao hơn đáng kể (3 instance EC2 chuyên trách mỗi môi trường).
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Ansible playbooks (`FUN-004`).
* **Rủi ro**: Lỗi bảo trì thủ công trong quá trình cập nhật OS.

### Phương án 3: Cấu hình Managed Thay thế (AWS AppConfig + CoreDNS)
* **Mô tả**: Thay thế hoàn toàn Nacos bằng AWS AppConfig cho cấu hình động và CoreDNS cho service discovery.
* **Ưu điểm**: Dịch vụ cấu hình serverless managed bởi AWS.
* **Nhược điểm**: Vi phạm yêu cầu `FUN-009`; yêu cầu tái cấu trúc toàn bộ tích hợp SDK của ~40 microservices.
* **Tác động Bảo mật**: Rất tốt.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Thấp.
* **Tác động Chi phí**: Chi phí theo lượt gọi API AppConfig.
* **Phụ thuộc Nhà cung cấp**: Cao (API độc quyền AWS AppConfig).
* **Độ phức tạp Di chuyển**: Cao (Viết lại mã nguồn microservice).
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Khách hàng từ bỏ yêu cầu Nacos.
* **Rủi ro**: Chi phí tái cấu trúc ứng dụng cao.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: Nacos trên EKS | Phương án 2: EC2 Chuyên trách | Phương án 3: AWS AppConfig |
| :--- | :--- | :--- | :--- |
| **Tuân thủ Yêu cầu (`FUN-009`)** | **Tuân thủ 100%** | **Tuân thủ 100%** | Không Tuân thủ |
| **Độ trễ & Kết nối Nội bộ Cluster** | **Sub-Millisecond** | Trung bình | Trung bình |
| **Hiệu quả Chi phí (`CST-001`)** | **Cao** | Yếu (EC2 Chuyên trách) | Trung bình |
| **Chi phí Nhân công Vận hành** | Thấp | Cao | Tối thiểu |
| **Khả năng Đảo ngược** | **Dễ dàng Đảo ngược** | Có thể đảo ngược | Khó |

---

## Quyết định Đề xuất
**Phương án 1: Nacos Cluster Triển khai trên EKS (Private Application Subnets)**.

---

## Lý do Lựa chọn
Phương án 1 đáp ứng yêu cầu `FUN-009` mà không cần viết lại mã nguồn ứng dụng, mang lại độ trễ sub-millisecond cho các microservice nội bộ cluster, và tránh chi phí không cần thiết của các EC2 instance chuyên trách.

---

## Hệ quả
* **Tích cực**: Tuân thủ 100% yêu cầu chức năng; chi phí vận hành tối thiểu; hiệu năng mạng EKS pod native.
* **Tiêu cực**: Phụ thuộc tầng cơ sở dữ liệu MySQL cho lưu trữ cấu hình bền vững.
* **Trách nhiệm Vận hành Mới**: Giám sát sức khỏe Nacos Raft cluster và connection pool cơ sở dữ liệu.
* **Rủi ro Mới**: `RSK-ARC-002` (Độ trễ bầu chọn Raft leader khi reboot node).
* **Hệ quả Chi phí**: 0 chi phí hạ tầng bổ sung (tận dụng dung lượng worker EKS).

---

## Bằng chứng Xác minh
* Kiểm thử triển khai multi-AZ Nacos cluster và xác minh phân giải DNS xuyên namespace.

## Điều kiện Nghiệm thu
* Phê duyệt từ Kiến trúc sư Trưởng Ứng dụng và Trưởng nhóm DevOps.

## Triggers Xem xét lại
* Phát hiện độ trễ nghiêm trọng inter-pod trong quá trình đồng bộ Nacos Raft.

## Tác động Triển khai
* Manifest Nacos Helm chart / K8s được triển khai vào các subnet application private của EKS trong Phase 3.
