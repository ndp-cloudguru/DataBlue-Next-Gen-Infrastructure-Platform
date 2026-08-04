# Sổ ký Rủi ro (Risk Register): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Quản trị & Phân loại Rủi ro

Tài liệu này chứa **Sổ ký Rủi ro (Risk Register)** toàn diện cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Các rủi ro được phân loại thành mười miền phân loại tiêu chuẩn:
1. **Không chắc chắn về Yêu cầu** (`RSK-UNC`): Thiếu dữ liệu tải công việc của khách hàng, định kích thước chưa được xác nhận, các mục tiêu chưa nêu rõ.
2. **Kiến trúc** (`RSK-ARC`): Phức tạp khi tích hợp đa công cụ, đánh đổi cấu trúc.
3. **Độ Sẵn sàng** (`RSK-AVL`): Sự cố ngắt kết nối, nhầm lẫn giữa multi-AZ và DR, phơi nhiễm sự cố vùng.
4. **Khả năng Mở rộng** (`RSK-SCL`): Nút thắt dung lượng, giới hạn mở rộng pod/node, giới hạn kết nối database.
5. **Bảo mật** (`RSK-SEC`): Kiểm soát truy cập, lộ credentials, bán kính ảnh hưởng, cấp quyền IAM quá mức.
6. **Dữ liệu** (`RSK-DAT`): Bất tương thích giao thức database, khôi phục sao lưu chưa được xác minh.
7. **Vận hành** (`RSK-OPS`): Gánh nặng bảo trì vận hành, thiếu SLOs, kiểm soát thay đổi production.
8. **Chi phí** (`RSK-CST`): Đột biến chi phí dịch vụ managed, chi tiêu tự động mở rộng không kiểm soát, lạm phát log observability.
9. **Phụ thuộc Nhà cung cấp** (`RSK-VND`): Trói buộc nhà cung cấp đám mây vs bảo trì vận hành mã nguồn mở.
10. **Triển khai** (`RSK-DEL`): Phức tạp module IaC, chậm tiến độ.

---

## 2. Nhật ký Rủi ro Toàn diện

### 1. Không chắc chắn về Yêu cầu (`RSK-UNC`)

#### `RSK-UNC-001`: Thiếu Hồ sơ Tải CPU và Bộ nhớ
* **Mô tả Rủi ro**: Việc thiếu các metric CPU và bộ nhớ cho từng dịch vụ trên ~40 microservices có thể dẫn tới định kích thước node sai lệch nghiêm trọng.
* **Danh mục**: Không chắc chắn về Yêu cầu
* **Nguyên nhân**: Khách hàng không thể cung cấp các metric đo đạc container trong Giai đoạn 0 (`OPEN-001`).
* **Hậu quả**: Cấp phát thừa node AWS (phát sinh chi phí lớn) hoặc cấp phát thiếu node (pod bị crash loop).
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)
* **Xác suất**: Cao | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Phân tầng định kích thước mặc định dự kiến ban đầu (`ASM-006`).
* **Biện pháp Giảm thiểu Đề xuất**: Triển khai tự động mở rộng Karpenter JIT (`ADR-005`) và chạy kiểm thử đo đạc container trên môi trường Test.
* **Phương án Dự phòng**: Triển khai các bộ khuyến nghị tài nguyên pod động (Goldilocks / VPA) để điều chỉnh dynamic requests.
* **Chủ sở hữu**: Chuyên viên FinOps / Kiến trúc sư Đám mây | **Trạng thái**: Active | **Điểm Đánh giá**: Benchmark Giai đoạn 1.

#### `RSK-UNC-002`: Thiếu Thông tin RPS Lưu lượng và Kết nối Đồng thời
* **Mô tả Rủi ro**: Việc thiếu các metric Yêu cầu Mỗi Giây (RPS) đỉnh và kết nối người dùng đồng thời có rủi ro gây nghẽn mạng và load balancer.
* **Danh mục**: Không chắc chắn về Yêu cầu
* **Nguyên nhân**: Hồ sơ lưu lượng khách hàng chưa được nêu rõ.
* **Hậu quả**: Cạn kiệt ALB target group ingress và lỗi timeout HTTP 504 API.
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Xác suất**: Cao | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Cấu hình mở rộng dự kiến cho controller ALB ingress.
* **Biện pháp Giảm thiểu Đề xuất**: Thực thi kiểm thử tải giả lập trong đợt dựng mẫu Giai đoạn 3.
* **Phương án Dự phòng**: Bật AWS WAF rate-limiting và làm nóng trước ALB (pre-warming).
* **Chủ sở hữu**: Kiến trúc sư Trưởng Hạ tầng | **Trạng thái**: Active | **Điểm Đánh giá**: Thực thi kiểm thử tải.

#### `RSK-UNC-003`: Thiếu Thể tích Dữ liệu và Tỷ lệ Tăng trưởng Lưu trữ
* **Mô tả Rủi ro**: Việc thiếu baseline lưu trữ cơ sở dữ liệu và tỷ lệ tăng trưởng hàng tháng có rủi ro cạn kiệt EBS volume hoặc vượt ngân sách.
* **Danh mục**: Không chắc chắn về Yêu cầu
* **Nguyên nhân**: Các metric cơ sở dữ liệu của khách hàng chưa được xác nhận.
* **Hậu quả**: Lỗi ghi cơ sở dữ liệu do tràn ổ đĩa.
* **Yêu cầu Liên quan**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md), [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Xác suất**: Cao | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Bật tự động mở rộng dung lượng lưu trữ AWS EBS / RDS.
* **Biện pháp Giảm thiểu Đề xuất**: Thu thập dung lượng ổ đĩa cơ sở dữ liệu hiện tại từ DBA của khách hàng.
* **Phương án Dự phòng**: Đặt cảnh báo CloudWatch sử dụng lưu trữ tại ngưỡng 75% dung lượng.
* **Chủ sở hữu**: Quản trị viên Cơ sở Dữ liệu | **Trạng thái**: Active | **Điểm Đánh giá**: Kiểm toán dữ liệu Giai đoạn 1.

#### `RSK-UNC-004`: ~40 Dịch vụ chưa rõ Mức độ Quan trọng và Phụ thuộc
* **Mô tả Rủi ro**: Việc đối xử với tất cả 40 microservices với mức ưu tiên như nhau có rủi ro phân bổ sai lệch tài nguyên sẵn sàng cao và sao lưu.
* **Danh mục**: Không chắc chắn về Yêu cầu
* **Nguyên nhân**: Thiếu định nghĩa phân tầng hệ thống nghiệp vụ (Tier 1 Cốt lõi vs Tier 3 Xử lý lô).
* **Hậu quả**: Cấp phát thừa cho các dịch vụ background không quan trọng trong khi bảo vệ thiếu cho các dịch vụ thanh toán cốt lõi.
* **Yêu cầu Liên quan**: [`BUS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-001`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md), [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Xác suất**: Trung bình | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Kiến trúc mặc định multi-AZ cho tất cả.
* **Biện pháp Giảm thiểu Đề xuất**: Chủ sở hữu Sản phẩm phía khách hàng lập Ma trận Phân tầng Dịch vụ (Tier 1/2/3).
* **Phương án Dự phòng**: Ưu tiên các microservice Tier 1 trong chuỗi failover DR.
* **Chủ sở hữu**: Kiến trúc sư Trưởng Ứng dụng | **Trạng thái**: Active | **Điểm Đánh giá**: Ký duyệt Ma trận Dịch vụ.

---

### 2. Kiến trúc & Triển khai (`RSK-ARC`, `RSK-DEL`)

#### `RSK-ARC-001`: Trôi lệch Trách nhiệm Tích hợp CI/CD Đa Công cụ
* **Mô tả Rủi ro**: Sự chồng chéo trách nhiệm giữa GitLab, Jenkins, và Ansible có thể gây trôi lệch cấu hình pipeline và lỗi build.
* **Danh mục**: Kiến trúc
* **Nguyên nhân**: Chỉ thị từ khách hàng yêu cầu 3 công cụ CI/CD đồng thời (`FUN-002`–`FUN-004`).
* **Hậu quả**: Chồng chéo các đợt release, triển khai bị lỗi, và trùng lặp các bước build.
* **Yêu cầu Liên quan**: [`BUS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-005`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md)
* **Xác suất**: Trung bình | **Mức độ Ảnh hưởng**: Trung bình | **Mức độ Phơi nhiễm**: Trung bình
* **Kiểm soát Hiện tại**: Mô hình Phủ Phân tầng Lai chuẩn hóa trong [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md).
* **Biện pháp Giảm thiểu Đề xuất**: Tài liệu hóa ranh giới hợp đồng công cụ rõ ràng (GitLab: Trigger → Jenkins: Build → Ansible: Deploy).
* **Phương án Dự phòng**: Quay về pipeline bản địa GitLab CI nếu Webhook liên công cụ thất bại.
* **Chủ sở hữu**: Trưởng nhóm DevOps | **Trạng thái**: Active | **Điểm Đánh giá**: Kiểm thử CI/CD dry-run.

#### `RSK-ARC-002`: Phức tạp của Stateful Workloads trên Kubernetes
* **Mô tả Rủi ro**: Việc host các ứng dụng stateful phức tạp (RabbitMQ, Nacos, MySQL) trên EKS có rủi ro độ trễ attach volume trong khi tái lập lịch pod.
* **Danh mục**: Kiến trúc
* **Nguyên nhân**: Pod Kubernetes tái lập lịch đòi hỏi gỡ EBS volume và attach lại xuyên các node.
* **Hậu quả**: Gián đoạn tạm thời cơ sở dữ liệu hoặc message broker trong khi failover node.
* **Yêu cầu Liên quan**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md)
* **Xác suất**: Trung bình | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: AWS EBS CSI driver với các volume `gp3`.
* **Biện pháp Giảm thiểu Đề xuất**: Ưu tiên sử dụng AWS Managed Services (RDS, ElastiCache) cho các database stateful quan trọng khi khả thi.
* **Phương án Dự phòng**: Sử dụng nhân bản cấp ứng dụng multi-AZ thay vì phụ thuộc vào việc re-attach volume.
* **Chủ sở hữu**: Kiến trúc sư Dữ liệu / Trưởng nhóm Hạ tầng | **Trạng thái**: Active | **Điểm Đánh giá**: Đánh giá các ADR.

---

### 3. Bảo mật & Truy cập (`RSK-SEC`)

#### `RSK-SEC-001`: Lộ Credentials Pipeline CI/CD
* **Mô tả Rủi ro**: Lưu trữ static AWS IAM access keys bên trong các Jenkins build node hoặc biến GitLab có rủi ro rò rỉ secret.
* **Danh mục**: Bảo mật
* **Nguyên nhân**: Các script triển khai mệnh lệnh truy cập trực tiếp các cloud APIs.
* **Hậu quả**: Truy cập trái phép vào hạ tầng AWS production.
* **Yêu cầu Liên quan**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`FUN-002`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-004`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-004`](../03-decisions/ADR-004-cicd-operating-model.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Xác suất**: Trung bình | **Mức độ Ảnh hưởng**: Nghiêm trọng | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Bắt buộc xác thực liên minh AWS IRSA và OIDC (`ADR-011`).
* **Biện pháp Giảm thiểu Đề xuất**: Thực thi chính sách 0 static credentials trên toàn bộ các pipeline CI/CD (`AGENTS.md`).
* **Phương án Dự phòng**: Quét secret repository Git tự động (git-leaks) trong pre-commit hooks.
* **Chủ sở hữu**: Trưởng nhóm Bảo mật Đám mây | **Trạng thái**: Active | **Điểm Đánh giá**: Kiểm toán bảo mật.

#### `RSK-SEC-002`: Cấp quyền IAM và Kubernetes RBAC Quá mức
* **Mô tả Rủi ro**: Các chính sách IAM quá rộng (ví dụ `AdministratorAccess`) gán cho vai trò lập trình viên hoặc service account pod có rủi ro vi phạm bảo mật.
* **Danh mục**: Bảo mật
* **Nguyên nhân**: Cấu hình quyền truy cập tiện lợi khi phát triển.
* **Hậu quả**: Xóa tài nguyên trái phép hoặc leo thang đặc quyền xuyên namespace.
* **Yêu cầu Liên quan**: [`SEC-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-011`](../03-decisions/ADR-011-secrets-management.md)
* **Xác suất**: Trung bình | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Quy tắc tạo chính sách IAM đặc quyền tối thiểu trong [`AGENTS.md`](../../AGENTS.md).
* **Biện pháp Giảm thiểu Đề xuất**: Triển khai IAM Access Analyzer và các lượt quét kiểm toán RBAC tự động.
* **Phương án Dự phòng**: Thu hồi các quyền IAM dạng wildcard ngay lập tức khi phát hiện.
* **Chủ sở hữu**: Trưởng nhóm Bảo mật Đám mây | **Trạng thái**: Active | **Điểm Đánh giá**: Kiểm toán bảo mật.

#### `RSK-SEC-003`: Phơi nhiễm Bán kính Ảnh hưởng Xuyên Môi trường
* **Mô tả Rủi ro**: Sự cố hoặc cấu hình sai trên môi trường Test lan truyền sang Production.
* **Danh mục**: Bảo mật
* **Nguyên nhân**: Đặt chung Test và Prod trong cùng một cluster hoặc account.
* **Hậu quả**: Gián đoạn Production hoặc rò rỉ dữ liệu khách hàng do các hành động ở non-prod.
* **Yêu cầu Liên quan**: [`BUS-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`SEC-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-002`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-001`](../03-decisions/ADR-001-aws-account-strategy.md), [`ADR-002`](../03-decisions/ADR-002-environment-isolation.md)
* **Xác suất**: Thấp | **Mức độ Ảnh hưởng**: Nghiêm trọng | **Mức độ Phơi nhiễm**: Trung bình
* **Kiểm soát Hiện tại**: AWS Accounts và EKS Clusters riêng biệt cho Test và Prod (`ADR-001`, `ADR-002`).
* **Biện pháp Giảm thiểu Đề xuất**: Chặn toàn bộ VPC peering giữa Test và Production VPCs.
* **Phương án Dự phòng**: Tự động cô lập account bị sự cố qua AWS Organizations SCP.
* **Chủ sở hữu**: Trưởng nhóm Bảo mật Doanh nghiệp | **Trạng thái**: Active | **Điểm Đánh giá**: Ký duyệt kiến trúc.

---

### 4. Dữ liệu & Sẵn sàng (`RSK-DAT`, `RSK-AVL`)

#### `RSK-DAT-001`: Bất tương thích Giao thức Amazon DocumentDB và MongoDB
* **Mô tả Rủi ro**: Microservice sử dụng các tính năng nâng cao của MongoDB bị lỗi khi chạy nếu triển khai trên Amazon DocumentDB.
* **Danh mục**: Dữ liệu
* **Nguyên nhân**: DocumentDB giả lập APIs MongoDB nhưng thiếu sự tương đương hoàn toàn về cú pháp (ví dụ các giai đoạn aggregation cụ thể, loại index).
* **Hậu quả**: Lỗi runtime driver cơ sở dữ liệu ứng dụng và hỏng truy vấn microservice.
* **Yêu cầu Liên quan**: [`FUN-007`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Xác suất**: Cao | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Tạm hoãn quyết định [`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md) cho đến khi hoàn thành kiểm toán tương thích.
* **Biện pháp Giảm thiểu Đề xuất**: Thực thi quét tự động tương thích truy vấn so với ma trận hỗ trợ API của DocumentDB.
* **Phương án Dự phòng**: Triển khai Operator MongoDB xịn trên EKS hoặc MongoDB Atlas nếu DocumentDB không tương thích.
* **Chủ sở hữu**: Kiến trúc sư Trưởng Dữ liệu | **Trạng thái**: Active | **Điểm Đánh giá**: Kiểm toán tương thích mã nguồn.

#### `RSK-DAT-002`: Quy trình Khôi phục Sao lưu không được Kiểm thử Thường xuyên
* **Mô tả Rủi ro**: Các bản sao lưu cơ sở dữ liệu và cluster bị hỏng hoặc không thể khôi phục mà đội ngũ không phát hiện ra.
* **Danh mục**: Dữ liệu
* **Nguyên nhân**: Sao lưu được cấu hình nhưng thiếu các đợt diễn tập khôi phục được lên lịch.
* **Hậu quả**: Mất hoàn toàn dữ liệu nghiệp vụ trong kịch bản tấn công ransomware hoặc khôi phục thảm họa.
* **Yêu cầu Liên quan**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md)
* **Xác suất**: Trung bình | **Mức độ Ảnh hưởng**: Nghiêm trọng | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Chiến lược Sao lưu Lai quy định trong [`ADR-013`](../03-decisions/ADR-013-backup-strategy.md).
* **Biện pháp Giảm thiểu Đề xuất**: Lên lịch các đợt kiểm thử xác minh khôi phục tự động hàng tháng vào subnet Test cô lập.
* **Phương án Dự phòng**: Duy trì các bản sao sao lưu kép (AWS Backup snapshots + bản sao S3 Velero).
* **Chủ sở hữu**: Quản trị viên Cơ sở Dữ liệu / Trưởng nhóm Vận hành | **Trạng thái**: Active | **Điểm Đánh giá**: Kiểm toán sao lưu hàng tháng.

#### `RSK-AVL-001`: Nhầm lẫn Sẵn sàng Cao Multi-AZ với Khôi phục Thảm họa
* **Mô tả Rủi ro**: Giả định triển khai Multi-AZ đã bảo vệ khỏi sự cố mất hoàn toàn vùng, dẫn tới việc thiếu kế hoạch duy trì hoạt động liên tục.
* **Danh mục**: Độ Sẵn sàng
* **Nguyên nhân**: Nhầm lẫn giữa dư thừa vùng cục bộ (HA) với duy trì liên tục xuyên vùng (DR).
* **Hậu quả**: Nền tảng bị ngừng hoạt động hoàn toàn khi xảy ra sự cố vùng AWS hoặc lỗi vật lý.
* **Yêu cầu Liên quan**: [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md)
* **Xác suất**: Trung bình | **Mức độ Ảnh hưởng**: Nghiêm trọng | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Tách biệt định nghĩa NFR và đánh giá DR rõ ràng trong [`ADR-014`](../03-decisions/ADR-014-disaster-recovery.md).
* **Biện pháp Giảm thiểu Đề xuất**: Các bên liên quan phía khách hàng ký duyệt yêu cầu RTO/RPO chính thức và chiến lược DR.
* **Phương án Dự phòng**: Nhân bản các bản sao lưu cơ sở dữ liệu mã hóa và modules IaC sang vùng AWS thứ hai.
* **Chủ sở hữu**: Kiến trúc sư Doanh nghiệp / Kiến trúc sư Trưởng Đám mây | **Trạng thái**: Active | **Điểm Đánh giá**: Ký duyệt BCP.

---

### 5. Chi phí & Vận hành (`RSK-CST`, `RSK-OPS`)

#### `RSK-CST-001`: Tăng trưởng Chi phí Dịch vụ Managed và Cấp phát Thừa
* **Mô tả Rủi ro**: Chi phí dịch vụ AWS Managed (RDS, ElastiCache, Secrets Manager) tăng nhanh vượt quá ước tính ban đầu.
* **Danh mục**: Chi phí
* **Nguyên nhân**: Cấp phát các instance managed hạng cao trước khi đo đạc tải công việc thực nghiệm.
* **Hậu quả**: Chi tiêu đám mây AWS hàng tháng vượt ngân sách (`BUS-004`).
* **Yêu cầu Liên quan**: [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-006`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Xác suất**: Cao | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Thiết lập Mô hình Ước tính Chi phí FinOps Tham số (`CST-001`).
* **Biện pháp Giảm thiểu Đề xuất**: Cấu hình AWS Budgets và Cảnh báo Bất thường Chi phí AWS với thông báo ngưỡng.
* **Phương án Dự phòng**: Rightsizing instance hoặc chuyển các dịch vụ không quan trọng sang phương án Spot / self-hosted.
* **Chủ sở hữu**: Trưởng nhóm FinOps | **Trạng thái**: Active | **Điểm Đánh giá**: Xem xét hóa đơn hàng tháng.

#### `RSK-CST-002`: Chi phí Nạp Log Observability Không Kiểm soát
* **Mô tả Rủi ro**: Microservice ghi log debug hoặc thu thập metric độ biến động cao gây ra đột biến hóa đơn CloudWatch / OpenSearch lớn.
* **Danh mục**: Chi phí
* **Nguyên nhân**: Microservices đẩy log debug stdout không lọc trên Production.
* **Hậu quả**: Chi phí nạp và lưu trữ log hàng tháng cao (`CST-001`).
* **Yêu cầu Liên quan**: [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-002`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-012`](../03-decisions/ADR-012-observability.md)
* **Xác suất**: Cao | **Mức độ Ảnh hưởng**: Trung bình | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Kiến trúc Observability Lai định tuyến log thô tới lưu trữ S3 Glacier (`ADR-012`).
* **Biện pháp Giảm thiểu Đề xuất**: Thực thi lọc log level (`INFO`/`WARN` chỉ ở Production) tại daemonset Fluent Bit.
* **Phương án Dự phòng**: Triển khai lấy mẫu log (sampling) và rate-limiting tại tầng log collector.
* **Chủ sở hữu**: Kỹ sư Trưởng Vận hành | **Trạng thái**: Active | **Điểm Đánh giá**: Kiểm tra thể tích log hàng tuần.

#### `RSK-OPS-001`: Gánh nặng Vận hành Lớn của Middleware Self-Hosted
* **Mô tả Rủi ro**: Việc cố gắng self-host MySQL, RabbitMQ, và MongoDB trên EKS gây quá tải cho đội ngũ SRE nền tảng.
* **Danh mục**: Vận hành
* **Nguyên nhân**: Lựa chọn các operator mã nguồn mở để tiết kiệm chi phí dịch vụ managed AWS mà không có đủ nhân sự DBA.
* **Hậu quả**: Gián đoạn hệ thống khi cơ sở dữ liệu gặp sự cố do thiếu phản ứng DBA chuyên sâu.
* **Yêu cầu Liên quan**: [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md)–[`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Giả định Liên quan**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **ADR Liên quan**: [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md)–[`ADR-009`](../03-decisions/ADR-009-mongodb-deployment.md)
* **Xác suất**: Cao | **Mức độ Ảnh hưởng**: Cao | **Mức độ Phơi nhiễm**: Cao
* **Kiểm soát Hiện tại**: Hoãn các quyết định cơ sở dữ liệu stateful chờ đánh giá năng lực vận hành.
* **Biện pháp Giảm thiểu Đề xuất**: Thực thi đánh giá Tổng Chi phí Sở hữu (TCO) chính thức bao gồm cả chi phí nhân công SRE.
* **Phương án Dự phòng**: Chuyển đổi các cơ sở dữ liệu phức tạp sang AWS Managed Services (RDS, ElastiCache).
* **Chủ sở hữu**: Trưởng nhóm DevOps / Trưởng nhóm SRE | **Trạng thái**: Active | **Điểm Đánh giá**: Ký duyệt ADR Giai đoạn 1.
