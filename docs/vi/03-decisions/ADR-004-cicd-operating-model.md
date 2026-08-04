# ADR-004 — Mô hình Vận hành CI/CD (CI/CD Operating Model)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Trưởng nhóm DevOps, Kiến trúc sư Hạ tầng
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Đội ngũ Bảo mật
* **Yêu cầu Liên quan**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-SEC-001` (Lộ thông tin đăng nhập pipeline CI/CD), `RSK-ARC-001` (Sai lệch trách nhiệm pipeline đa công cụ)
* **Giả định Liên quan**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 6
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu của khách hàng chỉ định tích hợp đồng thời GitLab (`FUN-002`), Jenkins (`FUN-003`), và Ansible (`FUN-004`) để tự động hóa triển khai (`BUS-002`). Chúng ta phải định nghĩa một mô hình vận hành nhằm ngăn ngừa trùng lặp các bước pipeline, sai lệch cấu hình và lộ thông tin đăng nhập bảo mật.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Tuân thủ Yêu cầu Bộ Công cụ**: Đáp ứng đúng chỉ đạo của khách hàng về GitLab, Jenkins và Ansible.
2. **Phân tách Vận hành Rõ ràng**: Ánh xạ ranh giới rõ ràng để mỗi công cụ xử lý một miền trách nhiệm duy nhất.
3. **Bảo mật Thông tin Đăng nhập Pipeline**: Giới hạn thông tin đăng nhập triển khai trong các agent thực thi chuyên trách, bảo mật (`SEC-001`).
4. **GitOps & Kiểm soát Sai lệch Cấu hình**: Đảm bảo trạng thái môi trường mục tiêu duy trì tính khai báo và có thể kiểm toán (`BUS-002`).

---

## Các Hạn chế
* Phải tích hợp GitLab, Jenkins và Ansible theo đúng bắt buộc của các yêu cầu chức năng.

---

## Các Phương án Đang Đánh giá

### Phương án 1: CI/CD GitLab Thuần túy (Bỏ qua Jenkins & Ansible)
* **Mô tả**: Sử dụng duy nhất GitLab CI/CD cho quản lý mã nguồn, build container, kiểm thử và triển khai.
* **Ưu điểm**: Pipeline CI/CD đơn nhà cung cấp cực kỳ tinh gọn; luồng công việc lập trình viên đơn giản.
* **Nhược điểm**: Vi phạm yêu cầu `FUN-003` (Jenkins) và `FUN-004` (Ansible); bỏ qua các khoản đầu tư công cụ Jenkins/Ansible sẵn có của khách hàng.
* **Tác động Bảo mật**: Quản lý secret tập trung tốt.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Chi phí quản lý dàn trải công cụ tối thiểu.
* **Tác động Chi phí**: Chi phí bảo trì công cụ thấp.
* **Phụ thuộc Nhà cung cấp**: Cao (Khóa vào hệ sinh thái GitLab).
* **Độ phức tạp Di chuyển**: Cao (Viết lại các pipeline Jenkins legacy).
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Khách hàng từ bỏ yêu cầu Jenkins/Ansible.
* **Rủi ro**: Không tuân thủ định hướng nền tảng của khách hàng.

### Phương án 2: CI/CD Jenkins Thuần túy (Bỏ qua GitLab CI & Ansible)
* **Mô tả**: Trigger build trực tiếp từ Webhook trong Jenkins, thực thi build container và chạy script triển khai trực tiếp qua plugin Jenkins.
* **Ưu điểm**: Tận dụng được các tài sản script build Jenkins sẵn có.
* **Nhược điểm**: Rủi ro cao về tràn ngập script mệnh lệnh (imperative); bỏ qua kiểm soát sai lệch cấu hình của Ansible (`FUN-004`); quản lý thông tin đăng nhập phức tạp bên trong Jenkins slaves.
* **Tác động Bảo mật**: Yếu. Lưu trữ cloud deployment key trực tiếp trên các build node Jenkins.
* **Tác động Sẵn sàng**: Trung bình.
* **Tác động Mở rộng**: Trung bình.
* **Tác động Vận hành**: Gánh nặng bảo trì script pipeline cao.
* **Tác động Chi phí**: Trung bình.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: Sai lệch cấu hình pipeline và lộ thông tin đăng nhập (`RSK-SEC-001`).

### Phương án 3: Mô hình Phủ Phân tầng Lai (GitLab → Jenkins → Ansible + GitOps)
* **Mô tả**: Thiết lập kiến trúc pipeline đa công cụ tách biệt:
  1. **GitLab**: Quản lý phiên bản mã nguồn, trigger Merge Request, và gửi webhook (`FUN-002`).
  2. **Jenkins**: Build CI, kiểm thử unit test, quét lỗ hổng container, đóng gói ảnh và push ECR (`FUN-003`).
  3. **Ansible**: Quản lý cấu hình hạ tầng, khắc phục sai lệch môi trường và thực thi triển khai (`FUN-004`).
  4. **ArgoCD / GitOps**: Đồng bộ trạng thái khai báo nội bộ cluster cho các Kubernetes manifest (`BUS-002`).
* **Ưu điểm**: Đáp ứng 100% yêu cầu bộ công cụ của khách hàng; thiết lập phân tách miền rõ ràng; loại bỏ lộ thông tin đăng nhập bằng cách giới hạn quyền IAM strictly cho Ansible control nodes / ArgoCD service accounts.
* **Nhược điểm**: Mô hình phủ đa công cụ đòi hỏi tài liệu hóa hợp đồng pipeline nghiêm ngặt (`RSK-ARC-001`).
* **Tác động Bảo mật**: Mạnh. Cô lập IAM role đặc quyền tối thiểu nghiêm ngặt qua các giai đoạn pipeline.
* **Tác động Sẵn sàng**: Cao. Mền sự cố bộ công cụ cô lập.
* **Tác động Mở rộng**: Cao. Các Jenkins build agent ngắn hạn.
* **Tác động Vận hành**: Đòi hỏi hợp đồng thực thi pipeline được tài liệu hóa.
* **Tác động Chi phí**: Chi phí hạ tầng runner tiêu chuẩn.
* **Phụ thuộc Nhà cung cấp**: Thấp (Kết nối công cụ lỏng lẻo).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Hợp đồng API chuẩn hóa giữa các endpoint trigger của Jenkins và Ansible.
* **Rủi ro**: `RSK-ARC-001` (Lỗi giao tiếp pipeline inter-tool).

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: GitLab Thuần | Phương án 2: Jenkins Thuần | Phương án 3: Lai (GitLab+Jenkins+Ansible) |
| :--- | :--- | :--- | :--- |
| **Tuân thủ Yêu cầu (`FUN-002..004`)** | Yếu (Vi phạm yêu cầu) | Yếu (Vi phạm yêu cầu) | **Mạnh (Tuân thủ 100%)** |
| **Bảo mật Thông tin Đăng nhập** | Trung bình | Yếu | **Mạnh** |
| **Kiểm soát Sai lệch Cấu hình** | Trung bình | Yếu | **Mạnh** |
| **Sự Rõ ràng Vận hành** | Cao | Thấp | **Trung bình-Cao** |
| **Khả năng Đảo ngược** | Có thể đảo ngược | Khó | **Dễ dàng Đảo ngược** |

---

## Quyết định Đề xuất
**Phương án 3: Mô hình Phủ Phân tầng Lai** (GitLab cho Mã nguồn/Trigger → Jenkins cho Build/Đóng gói CI → Ansible cho Cấu hình/Triển khai + GitOps).

---

## Lý do Lựa chọn
Phương án 3 đáp ứng nghiêm ngặt các yêu cầu chức năng `FUN-002`, `FUN-003`, và `FUN-004` đồng thời thiết lập ranh giới bảo mật rõ ràng ngăn ngừa Jenkins runners lưu trữ các thông tin đăng nhập triển khai đám mây dài hạn (`SEC-001`).

---

## Hệ quả
* **Tích cực**: Tuân thủ 100% yêu cầu bộ công cụ khách hàng; thông tin đăng nhập pipeline bảo mật; tự động quản lý sai lệch cấu hình qua Ansible.
* **Tiêu cực**: Duy trì nhiều điểm tích hợp công cụ.
* **Trách nhiệm Vận hành Mới**: Duy trì các hợp đồng API trigger giữa GitLab Webhooks, Jenkins jobs và Ansible execution hosts.
* **Rủi ro Mới**: `RSK-ARC-001` (Sai lệch hợp đồng giao diện pipeline).
* **Hệ quả Chi phí**: Chi phí node EC2 cho Jenkins master và máy chủ điều khiển Ansible.

---

## Bằng chứng Xác minh
* Mô phỏng trigger Webhook và chạy thử pipeline end-to-end trong tài khoản Shared Services.

## Điều kiện Nghiệm thu
* Phê duyệt từ Trưởng nhóm DevOps và Đội ngũ Bảo mật.

## Triggers Xem xét lại
* Khách hàng quyết định hợp nhất bộ công cụ CI/CD lên một nền tảng SaaS duy nhất.

## Tác động Triển khai
* Các playbook Ansible và pipeline Jenkins được soạn thảo trong Phase 3.
