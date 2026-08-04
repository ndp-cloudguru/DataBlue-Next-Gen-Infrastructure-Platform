🌐 **Language / Ngôn ngữ**: [English](README.md) | [Tiếng Việt](README.vi.md)

---

# Kiến trúc Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

> **THÔNG BÁO QUAN TRỌNG VỀ DỰ ÁN**: Việc triển khai hạ tầng kỹ thuật (mô-đun Terraform, manifest Kubernetes, Helm charts, kịch bản triển khai, hoặc cấp phát tài nguyên thực tế trên AWS) **CHƯA BẮT ĐẦU**. Thư mục lưu trữ này hiện chứa các sản phẩm của Giai đoạn 0 Yêu cầu Cơ sở, Stage 2 Quy cách Kiến trúc, Stage 3 Quyết định & Xác minh Rủi ro, Stage 4 Kế hoạch Triển khai, Stage 5 Kế hoạch Kiểm toán, và Thư mục Sơ đồ Mermaid Độc lập theo phương pháp Hướng Kiến trúc chuẩn hóa.

---

## 1. Tổng quan Dự án

Dự án **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`) là một sáng kiến cấp doanh nghiệp nhằm tái cấu trúc, chuẩn hóa, xác minh, thiết kế, mô hình hóa chi phí, lập kế hoạch và thiết lập khung kiểm toán cho một nền platform container cloud-native trên Amazon Web Services (AWS) chuẩn production, sẵn sàng cao, bảo mật và mở rộng linh hoạt.

Nền tảng mục tiêu sẽ vận hành:
* **Hệ thống Nghiệp vụ**: Khoảng 5–6 miền hệ thống nghiệp vụ (Business System Domains).
* **Microservices**: Khoảng 40 microservices phân tán chạy trên các môi trường Test và Production riêng biệt.
* **Dịch vụ Lưu trạng thái & Middleware**: Cơ sở dữ liệu Quan hệ (MySQL), Hàng chờ Thông điệp Phân tán (RabbitMQ), Cơ sở dữ liệu Bảng ghi Document (MongoDB), Bộ nhớ đệm In-Memory (Redis), và Trung tâm Phát hiện Dịch vụ/Cấu hình (Nacos).
* **Bộ Công cụ CI/CD & Vận hành**: GitLab cho quản lý mã nguồn và trigger pipeline, Jenkins cho điều phối build/test, và Ansible cho quản lý cấu hình và tự động hóa triển khai.
* **Năng lực Nền tảng**: Mở rộng quy mô đa tầng linh hoạt, sẵn sàng cao (HA), khôi phục thảm họa (DR), quản lý định danh và quyền truy cập (IAM/RBAC), giám sát/quan sát toàn diện (Observability), kiểm soát chi phí FinOps liên tục và khung kiểm toán Stage 5.

---

## 2. Trạng thái Hiện tại

* **Giai đoạn**: Stage 5 — Lập Kế hoạch Kiểm toán & Sơ đồ Kiến trúc Độc lập
* **Trạng thái**: **ĐANG HOẠT ĐỘNG / ĐÃ HOÀN THÀNH LẬP KẾ HOẠCH**
* **Các Cột mốc Đã Hoàn thành**:
  * Điều lệ Dự án & Quy tắc Quản trị (`PROJECT-CHARTER.md`, `AGENTS.md`, `AGENTS.vi.md`)
  * Tái cấu trúc & Chuẩn hóa Yêu cầu (`REQUIREMENTS-REGISTER.md`)
  * Đăng ký Giả định Kỹ thuật & Câu hỏi Mở (`ASSUMPTIONS-REGISTER.md`, `OPEN-QUESTIONS.md`)
  * Định nghĩa Yêu cầu Phi Chức năng & Tiêu chí Phê duyệt (`NON-FUNCTIONAL-REQUIREMENTS.md`, `ACCEPTANCE-CRITERIA.md`)
  * Đặc tả Kiến trúc Toàn diện Stage 2 (`ARCHITECTURE-SPECIFICATION.md`)
  * Danh mục ADR Master & 15 Tài liệu ADR Riêng biệt (`ADR-001` đến `ADR-015`)
  * Danh mục Rủi ro, Phụ thuộc Quyết định và Bộ Hồ sơ Xác minh Kiến trúc (`RISK-REGISTER.md`, `DECISION-DEPENDENCIES.md`, `ARCHITECTURE-VALIDATION.md`)
  * Lộ trình Triển khai 11 Giai đoạn Stage 4 (`IMPLEMENTATION-ROADMAP.md`)
  * Cấu trúc Phân rã Công việc 20 Gói Công việc (`WORK-BREAKDOWN-STRUCTURE.md`)
  * Khung Cổng Phê duyệt `GATE-01` đến `GATE-10` (`ACCEPTANCE-GATES.md`)
  * Mô hình Chi phí Tham số & 4 Kịch bản Chi phí (`COST-MODEL.md`, `COST-SCENARIOS.md`)
  * Mô hình Vận hành & Kế hoạch Sẵn sàng Hỗ trợ (`OPERATING-MODEL.md`, `SUPPORT-READINESS-PLAN.md`)
  * Chuẩn hóa Cấu trúc Thư mục Tài liệu (đổi tên `04-cost` thành `05-cost`)
  * Bộ Sản phẩm Lập Kế hoạch Kiểm toán Stage 5 (11 tài liệu trong `docs/vi/07-verification/`)
  * Cấu trúc Thư mục Tài liệu Song ngữ (`docs/en/` và `docs/vi/`)
  * Thư mục Sơ đồ Kiến trúc Độc lập (`diagrams/src/`)
* **Các Cột mốc Đang Chờ**:
  * Thu thập Số liệu Tải & Đo đạc Tải Khách hàng (Thực thi Phase 0)
  * Phê duyệt Chính thức của Con người đối với các ADR Đề xuất (`GATE-03`)
  * Cấp phát Hạ tầng AWS Nền tảng Phase 1 (`WP-002`)

---

## 3. Phạm vi Dự án

### Trong Phạm vi (Đã Hoàn thành Stage 5)
1. **Tái cấu trúc Yêu cầu**: Chuẩn hóa các yêu cầu chức năng, phi chức năng, bảo mật, vận hành và tài chính thành các danh mục đăng ký có thể truy xuất (`BUS-xxx`, `FUN-xxx`, `NFR-xxx`, `SEC-xxx`, `OPS-xxx`, `CST-xxx`).
2. **Quản trị Kiến trúc**: Quy định rõ ràng các quy tắc vận hành cho sự phê duyệt của con người, hạn chế của AI agent và các cổng chuyển giao giai đoạn.
3. **Đánh giá Kiến trúc Phân tách**: Đặc tả kiến trúc 17 mục bao phủ Bối cảnh Hệ thống, Logic, Triển khai, Mạng, Bảo mật, HA, Khả năng Mở rộng, Observability, Backup, DR và Kiến trúc Chi phí.
4. **Bộ Quyết định Kiến trúc**: 15 bản ADR toàn diện được đánh giá dựa trên yêu cầu, ràng buộc, rủi ro, năng lực vận hành, chi phí và tính có thể đảo ngược.
5. **Bộ Lập Kế hoạch Triển khai & Chi phí**: 19 sản phẩm kế hoạch được kiểm soát và truy xuất bao gồm WBS, Ma trận Phụ thuộc, Kế hoạch Bootstrap, Các Làn sóng Dịch chuyển, Chiến lược Rollback, Mô hình Chi phí 4 Kịch bản và Mô hình Vận hành RACI.
6. **Bộ Sản phẩm Lập Kế hoạch Kiểm toán**: 11 sản phẩm Stage 5 bao gồm Ma trận Truy xuất Yêu cầu, Kiểm toán Tuân thủ Kiến trúc, Đăng ký Bằng chứng Kiểm thử, Kiểm thử Bảo mật, Hiệu năng, HA, Backup/Restore, DR, Xác minh Chi phí và Báo cáo Sẵn sàng Phát hành Master.
7. **Tài liệu Song ngữ**: Cấu trúc cây tài liệu hoàn chỉnh bằng tiếng Anh (`docs/en/`) và tiếng Việt (`docs/vi/`).
8. **Sơ đồ Mermaid Độc lập**: Thư mục `diagrams/src/` chứa 14 sơ đồ nguồn `.mmd` thuần giúp dễ dàng render và bảo trì.

---

## 4. Cấu trúc Thư mục Lưu trữ

```text
datablue-nextgen-infra-platform/
├── README.md                                    # Master README Tiếng Anh
├── README.vi.md                                 # Master README Tiếng Việt (Bản này)
├── AGENTS.md                                    # Quy tắc quản trị & kiểm soát AI Agent (Tiếng Anh)
├── AGENTS.vi.md                                 # Quy tắc quản trị & kiểm soát AI Agent (Tiếng Việt)
├── diagrams/                                    # Thư mục Sơ đồ Kiến trúc Mermaid Độc lập
│   ├── README.md                                # Mục lục sơ đồ và hướng dẫn render
│   ├── render.py                                # Script Python tự động trích xuất & biên dịch sơ đồ
│   ├── src/                                     # File nguồn .mmd thuần (01-14)
│   ├── svg/                                     # Ảnh vector SVG rendered
│   └── png/                                     # Ảnh bitmap PNG rendered
└── docs/
    ├── en/                                      # Cây Tài liệu Tiếng Anh
    │   ├── 00-governance/
    │   ├── 01-requirements/
    │   ├── 02-architecture/
    │   ├── 03-decisions/
    │   ├── 04-planning/
    │   ├── 05-cost/
    │   ├── 06-operations/
    │   ├── 07-verification/
    │   └── 08-risks/
    └── vi/                                      # Cây Tài liệu Tiếng Việt (Bản dịch tiếng Việt)
        ├── 00-governance/
        ├── 01-requirements/
        ├── 02-architecture/
        ├── 03-decisions/
        ├── 04-planning/
        ├── 05-cost/
        ├── 06-operations/
        ├── 07-verification/
        └── 08-risks/
```

---

## 5. Quy ước & Mã Định danh Yêu cầu (Requirement Identifiers & Conventions)

Tất cả các sản phẩm của dự án tuân thủ nghiêm ngặt định dạng mã định danh (ID) chuẩn hóa để đảm bảo khả năng truy xuất nguồn gốc chéo 100% giữa các đặc tả, quyết định ADR, gói công việc và kịch bản kiểm toán:

* **Yêu cầu Kinh doanh**: `BUS-001` đến `BUS-004` (Mục tiêu Kinh doanh & Chi phí)
* **Yêu cầu Chức năng**: `FUN-001` đến `FUN-009` (Microservices, CI/CD, CSDL, & Nacos)
* **Yêu cầu Phi Chức năng**: `NFR-001` đến `NFR-003` (Sẵn sàng cao 99.9%, Karpenter Autoscaling & DR RTO/RPO SLAs)
* **Yêu cầu Bảo mật**: `SEC-001` đến `SEC-003` (Định danh IRSA OIDC, Subnet Cô lập, Mã hóa KMS & Cloudflare WAF)
* **Vận hành & Quan sát**: `OPS-001` đến `OPS-003` (Ghi log OpenSearch, Prometheus/Grafana APM & Kiểm soát FinOps)
* **Quản lý Chi phí**: `CST-001` đến `CST-002` (Mô hình Chi phí Tham số 4 Kịch bản & Savings Plans)
* **Giả định Kiến trúc**: `ASM-001` đến `ASM-005` (Tham số Tải & Năng lực Tính toán)
* **Nhật ký Quyết định Kiến trúc**: `ADR-001` đến `ADR-015` (Các Quyết định Lựa chọn Công nghệ Master)
* **Gói Công việc & Cổng Phê duyệt**: `WP-001` đến `WP-020`, `GATE-01` đến `GATE-10` (Lộ trình Triển khai 11 Giai đoạn)
* **Bằng chứng Kiểm toán**: `EVD-REQ-xxx`, `EVD-SEC-xxx`, `EVD-DR-xxx` (Bộ Sản phẩm Kiểm toán Stage 5)

---

## 6. Đề xuất Tổng thể & Điều hướng Quản trị

* **Đề xuất Tổng thể (Tiếng Anh)**: [`PROPOSAL.md`](docs/en/PROPOSAL.md)
* **Đề xuất Tổng thể (Tiếng Việt)**: [`PROPOSAL.vi.md`](docs/vi/PROPOSAL.md)
* **Thư mục Sơ đồ Độc lập**: [`diagrams/`](diagrams/)
* **Phương pháp luận**: Quản trị Hướng Kiến trúc
* **Quy tắc Agent (Tiếng Anh)**: [`AGENTS.md`](AGENTS.md)
* **Quy tắc Agent (Tiếng Việt)**: [`AGENTS.vi.md`](AGENTS.vi.md)
* **Mục lục Tài liệu Tiếng Anh**: [`docs/en/`](docs/en/)
* **Mục lục Tài liệu Tiếng Việt**: [`docs/vi/`](docs/vi/)
