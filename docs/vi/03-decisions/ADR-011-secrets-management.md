# ADR-011 — Topo Quản lý Secrets (Secrets Management Topology)

## Metadata
* **Trạng thái**: `Proposed` (Đề xuất)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Trưởng nhóm Bảo mật Đám mây, Trưởng nhóm DevOps
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp
* **Yêu cầu Liên quan**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-SEC-001` (Lộ thông tin đăng nhập pipeline CI/CD), `RSK-SEC-002` (Secrets chưa mã hóa trong etcd)
* **Giả định Liên quan**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 7, Mục 8
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `SEC-001` bắt buộc quản lý truy cập và phân quyền tập trung với 0 thông tin đăng nhập tĩnh lưu trữ trong repository hoặc ảnh container. Chúng ta phải lựa chọn một kiến trúc quản lý secret doanh nghiệp để nạp mật khẩu cơ sở dữ liệu, API token, và certificate vào các pod microservice trên môi trường Test và Production.

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Không có Thông tin Đăng nhập Tĩnh**: Loại bỏ hoàn toàn mật khẩu hardcode trong Git, pipeline CI/CD, hoặc ảnh container (`SEC-001`).
2. **Mã hóa Phong bì KMS & Nhật ký Kiểm toán**: Xoay vòng secret liên tục, mã hóa phong bì AWS KMS và ghi log kiểm toán CloudTrail.
3. **Chi phí Vận hành & Tích hợp Kubernetes**: Đồng bộ native vào các secret Kubernetes mà không cần container sidecar phức tạp trong pod.

---

## Các Hạn chế
* Việc nạp secrets phải hỗ trợ EKS IAM Roles for Service Accounts (IRSA).

---

## Các Phương án Đang Đánh giá

### Phương án 1: Secrets Kubernetes Native (Mã hóa Base64)
* **Mô tả**: Lưu trữ secret ứng dụng trực tiếp dạng các đối tượng Kubernetes Secret native trong etcd.
* **Ưu điểm**: Có sẵn trong Kubernetes; cú pháp manifest đơn giản.
* **Nhược điểm**: Mã hóa Base64 KHÔNG PHẢI là mã hóa bảo mật; secret rất dễ vô tình bị commit vào repository Git; thiếu xoay vòng secret tự động hoặc nhật ký kiểm toán tập trung.
* **Tác động Bảo mật**: Yếu. Lộ secret dạng plain-text cho bất kỳ ai có quyền đọc namespace.
* **Tác động Sẵn sàng**: Cao.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Rủi ro rò rỉ thông tin đăng nhập cao.
* **Tác động Chi phí**: Không tốn chi phí bổ sung.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Không.
* **Rủi ro**: `RSK-SEC-002` (Rò rỉ thông tin đăng nhập dạng plain-text trong Git repository hoặc etcd backup).

### Phương án 2: AWS Secrets Manager + External Secrets Operator (ESO)
* **Mô tả**: Tập trung master secret trong AWS Secrets Manager (mã hóa qua AWS KMS), tự động đồng bộ vào các Kubernetes secret ngắn hạn bên trong EKS qua External Secrets Operator (ESO) mã nguồn mở.
* **Ưu điểm**: Nhật ký kiểm toán AWS CloudTrail tập trung; tự động xoay vòng KMS key; ESO sử dụng xác thực IAM IRSA OIDC (`SEC-001`); không tốn overhead độ trễ sidecar.
* **Nhược điểm**: Chi phí API AWS Secrets Manager ($0.40/secret/tháng + $0.05 per 10k API calls).
* **Tác động Bảo mật**: Rất tốt. Mã hóa phong bì KMS + phân quyền chính sách IAM nghiêm ngặt theo từng tài khoản môi trường.
* **Tác động Sẵn sàng**: Cao (AWS Secrets Manager SLA 99.9%).
* **Tác động Mở rộng**: Rất tốt.
* **Tác động Vận hành**: Bảo trì vận hành thấp (chuyển giao bảo trì kho secret cho AWS).
* **Tác động Chi phí**: Chi tiêu hàng tháng thấp dự đoán được (~$20-50/tháng tổng cộng).
* **Phụ thuộc Nhà cung cấp**: Trung bình (API AWS Secrets Manager).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Tích hợp AWS KMS và EKS OIDC IRSA.
* **Rủi ro**: Bị rate limit API nếu cấu hình khoảng thời gian refresh sai (được giảm thiểu nhờ caching ESO).

### Phương án 3: Cluster HashiCorp Vault (Self-Hosted trên EKS hoặc Vault Chuyên trách)
* **Mô tả**: Triển khai một cluster HashiCorp Vault 3-node chuyên trách với Vault Agent Injector sidecars.
* **Ưu điểm**: Linh hoạt đa đám mây; sinh secret động (thông tin đăng nhập DB ngắn hạn).
* **Nhược điểm**: Độ phức tạp vận hành cao; quản lý unseal key; overhead bộ nhớ/CPU sidecar trên mọi pod; chi phí bản quyền cao nếu yêu cầu các tính năng enterprise.
* **Tác động Bảo mật**: Rất tốt.
* **Tác động Sẵn sàng**: Cao nếu được quản lý bởi đội ngũ Vault SRE chuyên trách.
* **Tác động Mở rộng**: Cao.
* **Tác động Vận hành**: Gánh nặng vận hành lớn lên đội ngũ nền tảng.
* **Tác động Chi phí**: Cao (Tính toán Vault self-hosted + nhân công vận hành hoặc bản quyền Vault HCP).
* **Phụ thuộc Nhà cung cấp**: Thấp (Độc lập đám mây).
* **Độ phức tạp Di chuyển**: Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Đội ngũ kỹ sư Bảo mật/Vault chuyên trách.
* **Rủi ro**: Mất unseal key hoặc hỏng backend lưu trữ Vault.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: K8s Secrets Native | Phương án 2: AWS Secrets Manager + ESO | Phương án 3: HashiCorp Vault |
| :--- | :--- | :--- | :--- |
| **Bảo mật & Mã hóa KMS** | Yếu | **Mạnh** | **Mạnh** |
| **Nhật ký Kiểm toán (`SEC-001`)** | Yếu | **Mạnh (CloudTrail)** | Mạnh (Vault Audit) |
| **Sự Đơn giản Vận hành** | Cao | **Cao (Managed)** | Yếu (Overhead Cao) |
| **Hiệu quả Chi phí** | Cao | **Cao** | Thấp |
| **Khả năng Đảo ngược** | Dễ dàng Đảo ngược | **Có thể đảo ngược** | Khó |

---

## Quyết định Đề xuất
**Phương án 2: AWS Secrets Manager + External Secrets Operator (ESO)**.

---

## Lý do Lựa chọn
Phương án 2 thực thi bảo mật đặc quyền tối thiểu (`SEC-001`), cung cấp vết kiểm toán AWS CloudTrail bất biến, và chuyển giao bảo trì kho secret cho AWS, tránh gánh nặng vận hành lớn của HashiCorp Vault đồng thời loại bỏ hoàn toàn thông tin đăng nhập plain-text tĩnh trong Git repository.

---

## Hệ quả
* **Tích cực**: Tuân thủ 100% chính sách IAM IRSA đặc quyền tối thiểu; tự động xoay vòng secret; 0 thông tin đăng nhập tĩnh trong Git.
* **Tiêu cực**: Phí API AWS Secrets Manager hàng tháng nhỏ (~$20-50/tháng).
* **Trách nhiệm Vận hành Mới**: Quản lý custom resources ExternalSecrets và thiết lập khoảng thời gian đồng bộ refresh hợp lý.
* **Rủi ro Mới**: Rate limit API Secrets Manager nếu khoảng thời gian refresh đặt dưới 1 phút.
* **Hệ quả Chi phí**: ~$0.40 mỗi secret mỗi tháng.

---

## Bằng chứng Xác minh
* Kiểm thử xác thực External Secrets Operator IAM IRSA và xác minh đồng bộ secret.

## Điều kiện Nghiệm thu
* Phê duyệt từ Trưởng nhóm Bảo mật Đám mây và Trưởng nhóm DevOps.

## Triggers Xem xét lại
* Yêu cầu chuyển giao đa đám mây bắt buộc kho secret độc lập với đám mây.

## Tác động Triển khai
* Manifest ESO Helm chart và ExternalSecret CRD được triển khai trong Phase 3.
