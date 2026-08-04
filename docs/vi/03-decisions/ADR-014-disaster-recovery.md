# ADR-014 — Chiến lược Khôi phục Thảm họa (Disaster Recovery Strategy)

## Metadata
* **Trạng thái**: `Deferred` (Tạm hoãn)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Hội đồng Kiến trúc Doanh nghiệp, Trưởng nhóm Hạ tầng Đám mây
* **Người Review**: Chủ sở hữu Sản phẩm Nghiệp vụ Khách hàng, Trưởng nhóm Bảo mật
* **Yêu cầu Liên quan**: [`NFR-003`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-UNC-003` (Chưa định nghĩa mục tiêu RTO/RPO), `RSK-AVL-001` (Phụ thuộc sự cố vùng đám mây AWS)
* **Giả định Liên quan**: [`ASM-007`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 13
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `NFR-003` bắt buộc có các cơ chế Khôi phục Thảm họa (DR) để đảm bảo tính liên tục nghiệp vụ trong các sự cố nghiêm trọng. **Khả năng Sẵn sàng Cao (Multi-AZ trong 1 vùng) KHÔNG ĐƯỢC NHẦM LẪN với Khôi phục Thảm họa (Failover Xuyên Vùng)**. Multi-AZ bảo vệ khỏi sự cố phần cứng/zone cục bộ, nhưng để ngỏ nền tảng trước nguy cơ mất hoàn toàn một Region AWS (`RSK-AVL-001`). Các chỉ số RTO và RPO cụ thể hiện chưa được xác nhận (`OPEN-003`).

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Mục tiêu Thời gian Khôi phục (RTO)**: Thời gian gián đoạn tối đa chấp nhận được trong sự cố vùng (`NFR-003`).
2. **Mục tiêu Điểm Khôi phục (RPO)**: Cửa sổ dữ liệu bị mất tối đa chấp nhận được trong sự cố vùng (`NFR-003`).
3. **Hệ số Chi phí Hạ tầng AWS**: Đánh giá việc nhân bản xuyên vùng và tính toán dự phòng ảnh hưởng thế nào tới chi tiêu đám mây hàng tháng (`CST-001`).
4. **Độ phức tạp Vận hành**: Tính kỷ luật vận hành đòi hỏi để thực thi failover DNS vùng tự động hoặc thủ công.

---

## Các Hạn chế
* Các mục tiêu RTO và RPO phải được ủy quyền chính thức bằng văn bản bởi chủ sở hữu sản phẩm nghiệp vụ trước khi lựa chọn topo DR.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Chỉ Sẵn sàng Cao Multi-AZ (Phụ thuộc Một Vùng, Không có DR)
* **Mô tả**: Dựa hoàn toàn vào dư thừa 3-AZ trong vùng AWS chính mà không nhân bản xuyên vùng.
* **Ưu điểm**: Chi phí thấp nhất (0 chi phí hạ tầng hay chi phí truyền dữ liệu vùng thứ hai).
* **Nhược điểm**: Toàn bộ nền tảng ngừng hoạt động khi mất hoàn toàn một Region AWS; rủi ro gián đoạn nghiệp vụ cao (`RSK-AVL-001`).
* **Tác động Bảo mật**: Tốt trong vùng chính.
* **Tác động Sẵn sàng**: Dễ bị tổn thương trước sự cố vùng.
* **Mục tiêu RTO / RPO**: RTO = Vô hạn (cho đến khi AWS khôi phục vùng chính); RPO = 0.
* **Tác động Vận hành**: Tối thiểu.
* **Tác động Chi phí**: Chi phí hạ tầng thấp nhất.
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Khách hàng ký phê duyệt chấp nhận rủi ro sự cố vùng.
* **Rủi ro**: `RSK-AVL-001` (Toàn bộ nghiệp vụ bị ngưng trệ khi có sự cố vùng AWS).

### Phương án 2: Sao lưu và Khôi phục (Cold Standby ở Vùng Thứ hai)
* **Mô tả**: Nhân bản các bản sao lưu cơ sở dữ liệu và Velero cluster manifests sang một S3 bucket ở vùng AWS thứ hai. Khi có thảm họa, các script IaC sẽ khởi tạo một cluster EKS hoàn toàn mới.
* **Ưu điểm**: Chi phí duy trì tối thiểu (chỉ tốn phí truyền dữ liệu S3 xuyên vùng).
* **Nhược điểm**: RTO cao (4 đến 24 giờ) để khởi tạo control plane EKS, node groups, và khôi phục trạng thái cơ sở dữ liệu.
* **Tác động Bảo mật**: Rất tốt (Bản sao S3 mã hóa xuyên vùng).
* **Tác động Sẵn sàng**: Trung bình.
* **Mục tiêu RTO / RPO**: RTO = 4–24 giờ; RPO < 1 giờ.
* **Tác động Vận hành**: Áp lực cao khi công bố thảm họa khẩn cấp và thực thi IaC.
* **Tác động Chi phí**: Chi phí duy trì hàng tháng rất thấp (~$50-100/tháng cho lưu trữ S3 xuyên vùng).
* **Phụ thuộc Nhà cung cấp**: Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Các script Terraform IaC mô-đun (`ADR-015`).
* **Rủi ro**: Lỗi thực thi script IaC trong quá trình failover khẩn cấp.

### Phương án 3: Chiến lược Pilot Light (Hạ tầng Tối thiểu ở Vùng Thứ hai)
* **Mô tả**: Cấp phát một dấu chân hạ tầng tối thiểu ở vùng thứ hai: các read-replica cơ sở dữ liệu xuyên vùng, VPC/subnets cấu hình sẵn, và control plane EKS ở trạng thái chờ. Các node pool EKS sẽ mở rộng khi failover.
* **Ưu điểm**: RTO nhanh hơn (1 đến 2 giờ); mất dữ liệu gần như bằng 0 (RPO < 15 phút).
* **Nhược điểm**: Chi phí duy trì hàng tháng ở mức trung bình cho control plane EKS thứ hai và các read-replica cơ sở dữ liệu.
* **Tác động Bảo mật**: Rất tốt.
* **Tác động Sẵn sàng**: Độ bền vững vùng mạnh mẽ.
* **Mục tiêu RTO / RPO**: RTO = 1–2 giờ; RPO < 15 phút.
* **Tác động Vận hành**: Đòi hỏi duy trì các module IaC vùng thứ hai.
* **Tác động Chi phí**: Chi tiêu duy trì hàng tháng ở mức trung bình (~$300-800/tháng).
* **Phụ thuộc Nhà cung cấp**: Thấp-Trung bình.
* **Độ phức tạp Di chuyển**: Trung bình.
* **Khả năng Đảo ngược**: Có thể đảo ngược.
* **Điều kiện tiên quyết**: Hỗ trợ nhân bản cơ sở dữ liệu xuyên vùng.
* **Rủi ro**: Độ trễ đồng bộ cơ sở dữ liệu xuyên vùng.

### Phương án 4: Warm Standby / Active-Active Đa Vùng
* **Mô tả**: Lưu trữ một cluster EKS active được thu nhỏ quy mô và cluster cơ sở dữ liệu active-active / active-passive thời gian thực ở vùng AWS thứ hai với Cloudflare GTM / DNS health-check failover.
* **Ưu điểm**: RTO gần như bằng 0 (< 5 phút); RPO gần như bằng 0 (< 1 phút).
* **Nhược điểm**: Cực kỳ đắt đỏ (gấp đôi chi phí hạ tầng cơ sở); phí truyền dữ liệu xuyên vùng cao; độ phức tạp vận hành cực lớn cho đồng bộ trạng thái cơ sở dữ liệu đa vùng.
* **Tác động Bảo mật**: Rất tốt.
* **Tác động Sẵn sàng**: Cao nhất (SLA độ sẵn sàng 99.999%).
* **Mục tiêu RTO / RPO**: RTO < 5 phút; RPO < 1 phút.
* **Tác động Vận hành**: Gánh nặng vận hành SRE đa vùng rất nặng.
* **Tác động Chi phí**: Chi tiêu AWS hàng tháng tăng gấp đôi (hệ số 2x).
* **Phụ thuộc Nhà cung cấp**: Cao.
* **Độ phức tạp Di chuyển**: Rất Cao.
* **Khả năng Đảo ngược**: Khó.
* **Điều kiện tiên quyết**: Năng lực active-active cơ sở dữ liệu đa vùng.
* **Rủi ro**: Sai lệch hỏng dữ liệu split-brain và nhân đôi hóa đơn.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: Chỉ Multi-AZ | Phương án 2: Sao lưu & Khôi phục | Phương án 3: Pilot Light | Phương án 4: Warm Standby |
| :--- | :--- | :--- | :--- | :--- |
| **Năng lực RTO** | Không có (Nhiều ngày) | 4–24 Giờ | **1–2 Giờ** | < 5 Phút |
| **Năng lực RPO** | Không có | < 1 Giờ | **< 15 Phút** | < 1 Phút |
| **Hệ số Chi phí AWS** | **1.0x (Cơ sở)** | **1.05x** | 1.3x | 2.0x (Gấp đôi) |
| **Chi phí Nhân công Vận hành** | **Thấp** | Trung bình | Trung bình | Cực kỳ Nặng |
| **Khả năng Đảo ngược** | **Dễ dàng Đảo ngược** | **Dễ dàng Đảo ngược** | Có thể đảo ngược | Khó |

---

## Quyết định Đề xuất
**Quyết định bị Tạm hoãn (Deferred)**.

---

## Lý do Lựa chọn
Lựa chọn một chiến lược Khôi phục Thảm họa khi chưa có tài liệu mục tiêu RTO và RPO là bị nghiêm cấm theo quy định quản trị.

Phương án 2 (Sao lưu & Khôi phục) hoặc Phương án 3 (Pilot Light) là các ứng viên kỹ thuật dẫn đầu, nhưng lựa chọn cuối cùng **được tạm hoãn chờ phân loại mức độ quan trọng hệ thống nghiệp vụ và phê duyệt RTO/RPO từ phía khách hàng** (`OPEN-003`).

---

## Bằng chứng Xác minh Cần thiết trước khi Phê duyệt
1. Phê duyệt bằng văn bản của khách hàng về các mục tiêu RTO và RPO theo từng hệ thống nghiệp vụ (`OPEN-003`).
2. Phê duyệt ngân sách FinOps cho chi tiêu hạ tầng vùng thứ hai.

## Điều kiện Nghiệm thu
* Phê duyệt bằng văn bản từ Chủ sở hữu Sản phẩm Nghiệp vụ, Hội đồng Kiến trúc Doanh nghiệp và Đội ngũ FinOps.

## Triggers Xem xét lại
* Hoàn thành xem xét Kế hoạch Liên tục Nghiệp vụ (BCP) Phase 1.

## Tác động Triển khai
* Các module IaC nền tảng trong Phase 3 được cấu trúc để độc lập với vùng (region-agnostic) hỗ trợ triển khai đa vùng nhanh chóng.
