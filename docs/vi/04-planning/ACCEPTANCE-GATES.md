# Khung Cổng Nghiệm thu (Acceptance Gates Framework): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Khung Cổng Nghiệm thu** chính thức cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Mỗi đợt chuyển giao giai đoạn dự án đều được bảo vệ bởi một cổng nghiệm thu bắt buộc. **Không giai đoạn nào được phép tiến hành nếu thiếu ký duyệt chính thức bằng văn bản từ những người có thẩm quyền phê duyệt được chỉ định.**

---

## 2. Danh mục Cổng Nghiệm thu Tổng thể (`CỔNG-01` đến `CỔNG-10`)

### `CỔNG-01`: Phê duyệt Yêu cầu Cơ sở (Requirement Baseline Approval)
* **Chuyển giao Giai đoạn**: Hoàn thành Giai đoạn 0 → Bắt đầu Giai đoạn 1
* **Bằng chứng Cần thiết**: Các tài liệu đã chuẩn hóa [`REQUIREMENTS-REGISTER.md`](../01-requirements/REQUIREMENTS-REGISTER.md), [`PROJECT-CHARTER.md`](../00-governance/PROJECT-CHARTER.md), và [`AGENTS.md`](../../AGENTS.md).
* **Người Phê duyệt Được ủy quyền**: Nhà tài trợ Dự án, Trưởng nhóm Kiến trúc Doanh nghiệp
* **Điều kiện Đạt**: 100% yêu cầu được gán các ID tiêu chuẩn (`BUS`, `FUN`, `NFR`, `SEC`, `OPS`, `CST`).
* **Hành động khi Thất bại**: Dừng thực thi dự án; quay lại Giai đoạn 0 để chuẩn hóa yêu cầu.
* **Đường hướng Khắc phục**: Cập nhật `REQUIREMENTS-REGISTER.md` và nộp lại.

---

### `CỔNG-02`: Phê duyệt Quy cách Kiến trúc (Architecture Specification Approval)
* **Chuyển giao Giai đoạn**: Hoàn thành Kiến trúc Stage 2 → Bắt đầu Xác minh ADR Stage 3
* **Bằng chứng Cần thiết**: Tài liệu 17 mục [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md).
* **Người Phê duyệt Được ủy quyền**: Kiến trúc sư Trưởng Đám mây, Hội đồng Kiến trúc Doanh nghiệp
* **Điều kiện Đạt**: Bao phủ hoàn chỉnh Bối cảnh Hệ thống, Logical, Triển khai, Mạng, Bảo mật, HA, Khả năng mở rộng, Khả năng quan sát, Sao lưu, DR, Chi phí, và Stack.
* **Hành động khi Thất bại**: Từ chối baseline kiến trúc; yêu cầu chỉnh sửa tài liệu.
* **Đường hướng Khắc phục**: Cập nhật `ARCHITECTURE-SPECIFICATION.md` và nộp lại.

---

### `CỔNG-03`: Phê duyệt Gói ADR (ADR Package Approval)
* **Chuyển giao Giai đoạn**: Hoàn thành Quyết định Stage 3 → Bắt đầu Thực thi Nền tảng AWS Giai đoạn 1
* **Bằng chứng Cần thiết**: Tài liệu tổng master [`ADR-REGISTER.md`](../03-decisions/ADR-REGISTER.md) và 15 ADR riêng lẻ (`ADR-001`..`015`).
* **Người Phê duyệt Được ủy quyền**: Hội đồng Kiến trúc Doanh nghiệp, Trưởng nhóm Bảo mật Đám mây, Trưởng nhóm FinOps
* **Điều kiện Đạt**: Chấp nhận chính thức bằng văn bản cho các ADR Đề xuất (`ADR-001`..`005`, `ADR-010`..`013`, `ADR-015`).
* **Hành động khi Thất bại**: Chặn thực thi mã nguồn IaC (`AGENTS.md`).
* **Đường hướng Khắc phục**: Chỉnh sửa các phương án đánh đổi ADR và nộp lại cho Hội đồng Kiến trúc.

---

### `CỔNG-04`: Nền tảng AWS Sẵn sàng (AWS Foundation Ready)
* **Chuyển giao Giai đoạn**: Hoàn thành Nền tảng Giai đoạn 1 → Bắt đầu Nền tảng Test Giai đoạn 2
* **Bằng chứng Cần thiết**: AWS Landing Zone đã cấp phát, S3 state buckets, VPC subnets, NAT gateways, và KMS keys (`WP-002`..`WP-004`).
* **Người Phê duyệt Được ủy quyền**: Kiến trúc sư Trưởng Hạ tầng, Trưởng nhóm Bảo mật Đám mây
* **Điều kiện Đạt**: 100% lưu trữ được mã hóa; 0 tuyến đường giữa subnet database và internet công cộng (`SEC-002`).
* **Hành động khi Thất bại**: Hủy cấp phát các subnet VPC không tuân thủ.
* **Đường hướng Khắc phục**: Sửa module mạng Terraform và apply lại.

---

### `CỔNG-05`: Nền tảng Test Sẵn sàng (Test Platform Ready)
* **Chuyển giao Giai đoạn**: Hoàn thành Nền tảng Test Giai đoạn 2 → Bắt đầu Dịch vụ Dùng chung Giai đoạn 3
* **Bằng chứng Cần thiết**: EKS Test cluster (`v1.30+`) vận hành mượt mà, ALB Ingress controller hoạt động, Cloudflare DNS / GTM, và tích hợp IRSA IAM (`WP-005`, `WP-006`).
* **Người Phê duyệt Được ủy quyền**: Trưởng nhóm DevOps, Kiến trúc sư Hạ tầng
* **Điều kiện Đạt**: `kubectl get nodes` trả về `Ready` trên cả 3 AZs; SSL Labs đạt hạng A cho các endpoint ingress test.
* **Hành động khi Thất bại**: Tạm dừng cài đặt các dịch vụ dùng chung.
* **Đường hướng Khắc phục**: Cấp phát lại EKS node groups và các ingress controller.

---

### `CỔNG-06`: Chấp nhận Thử nghiệm Kỹ thuật (Technical Pilot Accepted)
* **Chuyển giao Giai đoạn**: Hoàn thành Thử nghiệm Kỹ thuật Giai đoạn 6 → Bắt đầu Dựng Production Giai đoạn 7
* **Bằng chứng Cần thiết**: Báo cáo Benchmark Nghiệm thu Thử nghiệm Kỹ thuật (`WP-014`).
* **Người Phê duyệt Được ủy quyền**: Kiến trúc sư Trưởng Ứng dụng, Trưởng nhóm SRE, Trưởng nhóm DevOps
* **Điều kiện Đạt**: Độ trễ cấp phát node Karpenter < 60s; 0 lỗi HTTP 500 dưới đợt bùng nổ 100% tải; các dashboard Grafana được xác minh.
* **Hành động khi Thất bại**: Chặn dựng Production; tối ưu hóa cấu hình các microservice thử nghiệm.
* **Đường hướng Khắc phục**: Tinh chỉnh Karpenter NodePool CRDs và chạy lại kiểm thử tải.

---

### `CỔNG-07`: Phê duyệt Dựng Production (CAB Sign-Off)
* **Chuyển giao Giai đoạn**: Hoàn thành Giai đoạn 6 → Bắt đầu Cấp phát Hạ tầng Production Giai đoạn 7
* **Bằng chứng Cần thiết**: Ticket ủy quyền đã ký từ Hội đồng Phê duyệt Thay đổi (CAB), kết quả benchmark thử nghiệm, ký duyệt mô hình chi phí.
* **Người Phê duyệt Được ủy quyền**: Hội đồng Phê duyệt Thay đổi (CAB), Trưởng nhóm Bảo mật Doanh nghiệp, Trưởng nhóm FinOps
* **Điều kiện Đạt**: Phê duyệt chính thức bằng văn bản cấp phép cấp phát `DataBlue-Prod-Account`.
* **Hành động khi Thất bại**: Nghiêm cấm tạo các tài nguyên đám mây production (`AGENTS.md`).
* **Đường hướng Khắc phục**: Giải quyết các phản đối của CAB về bảo mật hoặc ngân sách và nộp lại ticket.

---

### `CỔNG-08`: Chấp nhận Sẵn sàng Production (Production Readiness Accepted)
* **Chuyển giao Giai đoạn**: Hoàn thành Sẵn sàng Giai đoạn 9 → Bắt đầu Bàn giao Vận hành Giai đoạn 10
* **Bằng chứng Cần thiết**: Báo cáo Xác minh Sẵn sàng Production & Khôi phục Thảm họa (`WP-018`).
* **Người Phê duyệt Được ủy quyền**: Kiến trúc sư Trưởng Đám mây, Trưởng nhóm Bảo mật Doanh nghiệp, Chủ sở hữu Sản phẩm Nghiệp vụ
* **Điều kiện Đạt**: Xác minh khôi phục database PITR 30 ngày; failover AZ giả lập thành công; kiểm thử failover DR xuyên vùng đạt SLA RTO/RPO.
* **Hành động khi Thất bại**: Chặn go-live production.
* **Đường hướng Khắc phục**: Khắc phục các nút thắt failover và chạy lại các đợt diễn tập DR.

---

### `CỔNG-09`: Ký duyệt Làn Di chuyển (Migration Wave Sign-Off)
* **Chuyển giao Giai đoạn**: Theo từng Làn Di chuyển (Làn 1 đến 5) → Làn Di chuyển tiếp theo
* **Bằng chứng Cần thiết**: Báo cáo xác minh tiêu chí đầu ra của làn (`MIGRATION-ONBOARDING-PLAN.md`).
* **Người Phê duyệt Được ủy quyền**: Chủ sở hữu Sản phẩm Hệ thống Nghiệp vụ, Trưởng nhóm DevOps
* **Điều kiện Đạt**: 100% microservice trong làn ở trạng thái `Ready`; tỷ lệ lỗi HTTP 5xx < 0.01%; hoàn thành 14 ngày hypercare.
* **Hành động khi Thất bại**: Thực thi các playbook rollback làn (`ROLLBACK-STRATEGY.md`).
* **Đường hướng Khắc phục**: Sửa lỗi container microservice trong môi trường Test trước khi triển khai lại.

---

### `CỔNG-10`: Nghiệm thu Bàn giao Vận hành (Operational Handover Acceptance)
* **Chuyển giao Giai đoạn**: Hoàn thành Giai đoạn 10 → Vận hành Nền tảng Liên tục
* **Bằng chứng Cần thiết**: Biên bản Nghiệm thu Bàn giao Vận hành đã ký, runbooks đã xác minh, kiểm toán bàn giao quyền truy cập (`SUPPORT-READINESS-PLAN.md`).
* **Người Phê duyệt Được ủy quyền**: Trưởng nhóm Vận hành / SRE Doanh nghiệp, Nhà tài trợ Dự án
* **Điều kiện Đạt**: Đội ngũ vận hành đã được đào tạo; 100% cảnh báo được định tuyến tới PagerDuty/Slack; runbooks đã được xác minh.
* **Hành động khi Thất bại**: Gia hạn hỗ trợ từ đội ngũ dự án hypercare.
* **Đường hướng Khắc phục**: Tổ chức thêm các buổi đào tạo SRE và cập nhật runbook vận hành.
