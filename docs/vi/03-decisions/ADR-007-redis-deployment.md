# ADR-007 — Chiến lược Triển khai Redis (Redis Deployment Strategy)

## Metadata
* **Trạng thái**: `Deferred` (Tạm hoãn)
* **Ngày tạo**: 2026-08-03
* **Chủ sở hữu Quyết định**: Kiến trúc sư Trưởng Dữ liệu, Trưởng nhóm Hạ tầng Đám mây
* **Người Review**: Hội đồng Kiến trúc Doanh nghiệp, Đội ngũ FinOps
* **Yêu cầu Liên quan**: [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`OPS-001`](../01-requirements/REQUIREMENTS-REGISTER.md)
* **Rủi ro Liên quan**: `RSK-UNC-001` (Thiếu chỉ số bộ nhớ cache), `RSK-OPS-001` (Bảo trì vận hành cache self-hosted)
* **Giả định Liên quan**: [`ASM-004`](../01-requirements/ASSUMPTIONS-REGISTER.md)
* **Tài liệu Kiến trúc Liên quan**: [`ARCHITECTURE-SPECIFICATION.md`](../02-architecture/ARCHITECTURE-SPECIFICATION.md) Mục 3, Mục 6
* **Thay thế**: Không
* **Bị thay thế bởi**: Không

---

## Bối cảnh
Yêu cầu `FUN-008` quy định một bộ nhớ in-memory Redis cache cho lưu trữ session tạm thời và caching dữ liệu tốc độ cao trên các microservices. Chúng ta phải đánh giá nên triển khai Redis bên trong EKS hay sử dụng Amazon ElastiCache for Redis. Dung lượng bộ nhớ cache, tỷ lệ eviction và tỷ lệ hit/miss hiện chưa được xác nhận (`OPEN-001`).

---

## Yếu tố Thúc đẩy Quyết định (Decision Drivers)
1. **Độ trễ Dưới Millisecond (Sub-Millisecond)**: Đảm bảo độ trễ đọc/ghi cache cực thấp (`FUN-008`).
2. **Sẵn sàng Cao & Lưu trữ Cache Bền vững**: Failover Multi-AZ và nhân bản dữ liệu mà không làm mất dữ liệu cache khi khởi động lại node (`NFR-001`).
3. **Sự Đơn giản Vận hành**: Loại bỏ bảo trì sharding cluster Redis thủ công và dịch chuyển slot.
4. **Tối ưu Chi phí**: Cân bằng phí node theo giờ của AWS managed cache so với mức tiêu thụ RAM của worker node (`CST-001`).

---

## Các Hạn chế
* Phải hỗ trợ giao thức API Redis 7.0+ tiêu chuẩn.

---

## Các Phương án Đang Đánh giá

### Phương án 1: Self-Hosted Redis Cluster trên EKS (Bitnami Helm / Redis Operator)
* **Mô tả**: Lưu trữ các pod Redis Sentinel hoặc Redis Cluster bên trong EKS sử dụng RAM của Kubernetes worker node backed bởi ephemeral hoặc EBS storage.
* **Ưu điểm**: Không tốn phí dịch vụ managed ElastiCache; toàn quyền kiểm soát các tham số cấu hình Redis; khả năng linh hoạt chuyển đổi đám mây hoàn hảo.
* **Nhược điểm**: Tiêu tốn RAM đắt đỏ của worker node; pod bị lập lịch lại sẽ gây ra cold-start cache hoặc overhead tái sharding; đòi hỏi quản lý slot cluster thủ công.
* **Tác động Bảo mật**: Trung bình. Mã hóa TLS và network policies cấu hình thủ công.
* **Tác động Sẵn sàng**: Trung bình. Pod bị lỗi gây ra miss cache tạm thời cho đến khi failover hoàn thành.
* **Tác động Mở rộng**: Đòi hỏi điều chỉnh phân bổ RAM StatefulSet thủ công.
* **Tác động Vận hành**: Đội ngũ SRE phải quản lý failover cluster và bảo trì node (`RSK-OPS-001`).
* **Tác động Chi phí**: Tận dụng dung lượng RAM sẵn có của EKS worker node.
* **Phụ thuộc Nhà cung cấp**: Rất Thấp.
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Dễ dàng Đảo ngược.
* **Điều kiện tiên quyết**: Có sẵn phân bổ RAM worker node.
* **Rủi ro**: `RSK-OPS-001` (Trục xuất pod cache gây quá tải dây chuyền xuống cơ sở dữ liệu).

### Phương án 2: Amazon ElastiCache for Redis (Replication Group Multi-AZ)
* **Mô tả**: Cluster Redis Amazon ElastiCache chuyên trách, managed hoàn toàn được triển khai trên nhiều Availability Zones với failover tự động.
* **Ưu điểm**: Độ trễ sub-millisecond; failover multi-AZ tự động (< 30 giây); giải phóng quản lý bộ nhớ khỏi worker node EKS; vá lỗi bảo mật do AWS quản lý.
* **Nhược điểm**: Giá instance theo giờ chuyên trách (các instance `cache.m6g`); rủi ro phát sinh phí truyền dữ liệu xuyên AZ.
* **Tác động Bảo mật**: Rất tốt. Mã hóa KMS at rest, mã hóa TLS in transit, xác thực IAM.
* **Tác động Sẵn sàng**: Mạnh (SLA 99.99%).
* **Tác động Mở rộng**: Dễ dàng mở rộng cluster online và mở rộng shard.
* **Tác động Vận hành**: Gánh nặng vận hành tối thiểu cho đội DevOps.
* **Tác động Chi phí**: Chi tiêu cố định hàng tháng AWS ở mức Trung bình.
* **Phụ thuộc Nhà cung cấp**: Thấp-Trung bình (Tương thích giao thức Redis tiêu chuẩn).
* **Độ phức tạp Di chuyển**: Thấp.
* **Khả năng Đảo ngược**: Có thể đảo ngược kèm di chuyển.
* **Điều kiện tiên quyết**: Subnet VPC Database Chuyên trách.
* **Rủi ro**: Cấp phát thừa bộ nhớ node cache trước khi đo đạc tải công việc.

---

## Đánh giá So sánh

| Tiêu chí Đánh giá | Phương án 1: Redis trên EKS | Phương án 2: Amazon ElastiCache for Redis |
| :--- | :--- | :--- |
| **Độ trễ & SLA** | Trung bình-Cao | **Sub-Millisecond (99.99%)** |
| **Chi phí Nhân công Vận hành** | Cao | **Tối thiểu** |
| **Tranh chấp RAM Worker Node** | Rủi ro Cao | **Không Tranh chấp** |
| **Dự đoán Chi phí** | Cao | Trung bình |
| **Khả năng Đảo ngược** | **Dễ dàng Đảo ngược** | Có thể đảo ngược |

---

## Quyết định Đề xuất
**Quyết định bị Tạm hoãn (Deferred)**.

---

## Lý do Lựa chọn
Quyết định giữa Amazon ElastiCache for Redis và Self-Hosted Redis trên EKS **được tạm hoãn chờ đo đạc bộ nhớ cache microservice** (`OPEN-001`).

Nếu tổng yêu cầu RAM cache nhỏ (< 4 GB), self-hosting trên EKS có thể tối ưu chi phí; nếu yêu cầu cache vượt quá 16 GB với độ truy cập đồng thời cao, ElastiCache là bắt buộc để bảo vệ sự ổn định của worker node.

---

## Bằng chứng Xác minh Cần thiết trước khi Phê duyệt
1. Dung lượng bộ nhớ cache microservice, chính sách eviction TTL và chỉ số truy vấn RPS (`OPEN-001`).
2. Phê duyệt trần chi phí từ FinOps.

## Điều kiện Nghiệm thu
* Nộp các benchmark bộ nhớ cache được xác minh và xem xét từ Hội đồng Kiến trúc.

## Triggers Xem xét lại
* Hoàn thành đo đạc tải công việc trong Phase 1.

## Tác động Triển khai
* Thiết kế mạng phân bổ các subnet DB chuyên trách có khả năng lưu trữ cả hai phương án.
