🌐 **Language / Ngôn ngữ / 语言**: [English](README.md) | [Tiếng Việt](README.vi.md) | [中文 (Chinese)](README.zh.md)

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

* **Giai đoạn**: Stage 5 — Lập Kế hoạch Kiểm toán & Cơ sở Tài liệu Tam ngữ (Trilingual Baseline)
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
  * Mô hình Chi phí Tham số & Kịch bản 1 đến 5 (`COST-MODEL.md`, `COST-SCENARIOS.md`)
  * Mô hình Vận hành & Kế hoạch Sẵn sàng Hỗ trợ (`OPERATING-MODEL.md`, `SUPPORT-READINESS-PLAN.md`)
  * Bộ Sản phẩm Lập Kế hoạch Kiểm toán Stage 5 (11 tài liệu trong `docs/vi/07-verification/`, `docs/en/07-verification/`, `docs/zh/07-verification/`)
  * **Cấu trúc Thư mục Tài liệu Tam ngữ** (`docs/en/`, `docs/vi/`, và `docs/zh/` với 58 tài liệu markdown mỗi ngôn ngữ)
  * **Gói Đề xuất Phát hành Executive Proposal** (`final_proposal/` chứa `PROPOSAL.vi.md`, `PROPOSAL.en.md`, và `PROPOSAL.zh.md`)
  * Thư mục Sơ đồ Kiến trúc Độc lập (`diagrams/src/`)
  * Báo cáo Phân tích Chi phí AWS Excel Đa ngôn ngữ & Script Generator (`cost_summary/`)

---

## 3. Phạm vi Dự án

### Trong Phạm vi (Đã Hoàn thành Stage 5)
1. **Tái cấu trúc Yêu cầu**: Chuẩn hóa các yêu cầu chức năng, phi chức năng, bảo mật, vận hành và tài chính thành các danh mục đăng ký có thể truy xuất (`BUS-xxx`, `FUN-xxx`, `NFR-xxx`, `SEC-xxx`, `OPS-xxx`, `CST-xxx`).
2. **Quản trị Kiến trúc**: Quy định rõ ràng các quy tắc vận hành cho sự phê duyệt của con người, hạn chế của AI agent và các cổng chuyển giao giai đoạn.
3. **Đánh giá Kiến trúc Phân tách**: Đặc tả kiến trúc 17 mục bao phủ Bối cảnh Hệ thống, Logic, Triển khai, Mạng, Bảo mật, HA, Khả năng Mở rộng, Observability, Backup, DR và Kiến trúc Chi phí.
4. **Bộ Quyết định Kiến trúc**: 15 bản ADR toàn diện được đánh giá dựa trên yêu cầu, ràng buộc, rủi ro, năng lực vận hành, chi phí và tính có thể đảo ngược.
5. **Bộ Lập Kế hoạch Triển khai & Chi phí**: 19 sản phẩm kế hoạch được kiểm soát và truy xuất bao gồm WBS, Ma trận Phụ thuộc, Kế hoạch Bootstrap, Các Làn sóng Dịch chuyển, Chiến lược Rollback, Mô hình Chi phí Kịch bản 1–5 và Mô hình Vận hành RACI.
6. **Bộ Sản phẩm Lập Kế hoạch Kiểm toán**: 11 sản phẩm Stage 5 bao gồm Ma trận Truy xuất Yêu cầu, Kiểm toán Tuân thủ Kiến trúc, Đăng ký Bằng chứng Kiểm thử, Kiểm thử Bảo mật, Hiệu năng, HA, Backup/Restore, DR, Xác minh Chi phí và Báo cáo Sẵn sàng Phát hành Master.
7. **Tài liệu Tam ngữ**: Cấu trúc cây tài liệu hoàn chỉnh bằng tiếng Anh (`docs/en/`), tiếng Việt (`docs/vi/`) và tiếng Trung (`docs/zh/`) với tính tương đương thông tin 100% (58 tài liệu mỗi cây).
8. **Gói Đề xuất Executive Proposal**: Bộ tài liệu đề xuất tổng thể tại `final_proposal/` (`PROPOSAL.vi.md`, `PROPOSAL.en.md`, `PROPOSAL.zh.md`).
9. **Sơ đồ Mermaid Độc lập**: Thư mục `diagrams/src/` chứa các sơ đồ nguồn `.mmd` thuần giúp dễ dàng render và bảo trì.

---

## 4. Cấu trúc Thư mục Lưu trữ

```text
datablue-nextgen-infra-platform/
├── README.md                                    # Master README Tiếng Anh
├── README.vi.md                                 # Master README Tiếng Việt (Bản này)
├── README.zh.md                                 # Master README Tiếng Trung (Bản tiếng Trung)
├── AGENTS.md                                    # Quy tắc quản trị & kiểm soát AI Agent (Tiếng Anh)
├── AGENTS.vi.md                                 # Quy tắc quản trị & kiểm soát AI Agent (Tiếng Việt)
├── final_proposal/                              # Gói Đề xuất Executive Proposal (Các bản Đa ngôn ngữ)
│   ├── README.md                                # Hướng dẫn & Mục lục gói đề xuất
│   ├── PROPOSAL.vi.md                           # Bản Đề xuất Executive Master Tiếng Việt (Bản chính thức)
│   ├── PROPOSAL.en.md                           # Bản Đề xuất Executive Master Tiếng Anh
│   └── PROPOSAL.zh.md                           # Bản Đề xuất Executive Master Tiếng Trung (Bản tiếng Trung)
├── cost_summary/                                # Báo cáo Phân tích Chi phí AWS Excel Đa ngôn ngữ & Script Master Generator
│   ├── generate_cost_excel.py                   # Script Python OpenPyXL Master Generator
│   ├── DataBlue_AWS_Cost_Analysis.xlsx          # Bảng tính Phân tích Chi phí Chi tiết Tiếng Việt
│   ├── DataBlue_AWS_Cost_Analysis_EN.xlsx       # Bảng tính Phân tích Chi phí Chi tiết Tiếng Anh
│   └── DataBlue_AWS_Cost_Analysis_CN.xlsx       # Bảng tính Phân tích Chi phí Chi tiết Tiếng Trung
├── diagrams/                                    # Thư mục Sơ đồ Kiến trúc Mermaid Độc lập
│   ├── README.md                                # Mục lục sơ đồ và hướng dẫn render
│   ├── render.py                                # Script Python tự động trích xuất & biên dịch sơ đồ
│   ├── src/                                     # File nguồn .mmd thuần
│   ├── svg/                                     # Ảnh vector SVG rendered
│   └── png/                                     # Ảnh bitmap PNG rendered
├── scenarios/                                   # Thư mục Mã nguồn Terraform Infrastructure as Code (IaC) cho 5 Scenario
│   ├── README.md                                # Hướng dẫn & Quy trình thực thi Terraform
│   ├── modules/                                 # 8 Mô-đun Terraform Tái sử dụng Chuẩn Production
│   │   ├── vpc/                                 # Mạng VPC 3-Tier (Public, Private App, Isolated DB)
│   │   ├── kms/                                 # AWS KMS Customer Managed Key (CMK)
│   │   ├── eks/                                 # Amazon EKS v1.30+ Control Plane, IRSA & Karpenter
│   │   ├── rds_mysql/                           # Amazon RDS MySQL Multi-AZ với Sao lưu PITR 30 Ngày
│   │   ├── elasticache_redis/                   # Amazon ElastiCache Redis Cluster với TLS & Auth Token
│   │   ├── amazon_mq_rabbitmq/                  # Amazon MQ RabbitMQ 3-Node Quorum Broker với AMQP TLS
│   │   ├── documentdb/                          # Amazon DocumentDB 3-Node Cluster (MongoDB Compatible)
│   │   └── opensearch/                          # Amazon OpenSearch Service Multi-AZ Cluster
│   ├── scenario-1-test-baseline/                # Scenario 1: Môi trường Test Chuẩn ($1,600-$2,400/tháng)
│   ├── scenario-2-prod-baseline/                # Scenario 2: Môi trường Production Baseline ($4,200-$6,100/tháng)
│   ├── scenario-3-prod-high-scale-ha/           # Scenario 3: Môi trường Production HA Quy mô lớn ($7,200-$10,500/tháng)
│   ├── scenario-4-prod-cross-region-dr/         # Scenario 4: Production Khôi phục Thảm họa Cross-Region DR ($10,000-$14,800/tháng)
│   └── scenario-5-enterprise-multi-account/     # Scenario 5: Kiến trúc Cách ly Đa Tài khoản Doanh nghiệp ($12,000-$18,500/tháng)
└── docs/
    ├── en/                                      # Cây Tài liệu Tiếng Anh (58 file Markdown)
    ├── vi/                                      # Cây Tài liệu Tiếng Việt (58 file Markdown)
    └── zh/                                      # Cây Tài liệu Tiếng Trung (58 file Markdown - 中文文档树)
        ├── 00-governance/
        ├── 01-requirements/
        ├── 02-architecture/
        ├── 03-decisions/
        ├── 04-planning/
        ├── 05-cost/
        ├── 06-operations/
        ├── 07-verification/
        ├── 08-risks/
        └── PROPOSAL.md
```

---

## 5. Quy chuẩn Định danh Yêu cầu

Tất cả sản phẩm dự án đều tuân thủ nghiêm ngặt định dạng ID chuẩn hóa để duy trì tính truy xuất 100% giữa đặc tả, ADR, gói công việc và test case kiểm toán:

* **Yêu cầu Nghiệp vụ**: `BUS-001` đến `BUS-004` (Mục tiêu Kính doanh & Ngân sách)
* **Yêu cầu Chức năng**: `FUN-001` đến `FUN-009` (Năng lực Nền tảng Microservices, CI/CD, DB & Nacos)
* **Yêu cầu Phi Chức năng**: `NFR-001` đến `NFR-003` (Sẵn sàng cao 99.9%, Mở rộng phút & SLAs DR)
* **Yêu cầu Bảo mật**: `SEC-001` đến `SEC-003` (Định danh IRSA OIDC, Subnet Cách ly, Mã hóa KMS & WAF)
* **Vận hành & Quan sát**: `OPS-001` đến `OPS-003` (Nhật ký OpenSearch, APM Prometheus/Grafana & FinOps)
* **Yêu cầu Quản lý Chi phí**: `CST-001` đến `CST-002` (Kịch bản Chi phí Tham số 1–5 & Savings Plans)
* **Giả định Kỹ thuật**: `ASM-001` đến `ASM-005` (Giả định Tải & Năng lực)
* **Quyết định Kiến trúc**: `ADR-001` đến `ADR-015` (Bộ Quyết định Công nghệ Master)
* **Gói Công việc & Cổng**: `WP-001` đến `WP-020`, `GATE-01` đến `GATE-10` (Lộ trình Triển khai 11 Phase)
* **Bằng chứng Kiểm thử**: `EVD-REQ-xxx`, `EVD-SEC-xxx`, `EVD-DR-xxx` (Bộ Hồ sơ Kiểm toán Stage 5)

---

## 6. Điều hướng Đề xuất & Quản trị

* **Gói Đề xuất Executive Proposal**: [`final_proposal/`](final_proposal/)
* **Đề xuất Executive (Tiếng Việt - Chính thức)**: [`final_proposal/PROPOSAL.vi.md`](final_proposal/PROPOSAL.vi.md)
* **Đề xuất Executive (Tiếng Anh)**: [`final_proposal/PROPOSAL.en.md`](final_proposal/PROPOSAL.en.md)
* **Đề xuất Executive (Tiếng Trung)**: [`final_proposal/PROPOSAL.zh.md`](final_proposal/PROPOSAL.zh.md)
* **Mục lục Tài liệu Tiếng Việt**: [`docs/vi/`](docs/vi/)
* **Mục lục Tài liệu Tiếng Anh**: [`docs/en/`](docs/en/)
* **Mục lục Tài liệu Tiếng Trung**: [`docs/zh/`](docs/zh/)
* **Thư mục Sơ đồ Độc lập**: [`diagrams/`](diagrams/)
* **Báo cáo & Generator Chi phí (Excel)**: [`cost_summary/`](cost_summary/)
* **Quy tắc Quản trị Agent (Tiếng Việt)**: [`AGENTS.vi.md`](AGENTS.vi.md)
* **Quy tắc Quản trị Agent (Tiếng Anh)**: [`AGENTS.md`](AGENTS.md)
