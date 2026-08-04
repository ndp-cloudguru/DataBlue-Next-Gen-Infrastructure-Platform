# Kế hoạch Tối ưu Chi phí (Cost Optimization Plan): Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định **Chiến lược Tối ưu Chi phí FinOps & Quản trị** cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

Được quản trị bởi các yêu cầu [`BUS-004`](../01-requirements/REQUIREMENTS-REGISTER.md), [`CST-001`](../01-requirements/REQUIREMENTS-REGISTER.md), và [`CST-002`](../01-requirements/REQUIREMENTS-REGISTER.md).

---

## 2. 12 Trụ cột Tối ưu Chi phí FinOps

1. **Tự động Co giảm Quy mô Môi trường Non-Production**: Lên lịch tự động thu nhỏ các worker node EKS Test ngoài giờ làm việc (giảm 70% số lượng node vào ban đêm/cuối tuần), tiết kiệm ~35% tính toán non-prod.
2. **Karpenter Just-in-Time Bin-Packing**: Loại bỏ lãng phí từ việc cấp phát trước EC2 Auto Scaling Group bằng cách tự động khớp kích thước node với yêu cầu pod (`ADR-005`), tiết kiệm 15-25% tính toán thuần.
3. **Phân tầng EC2 Spot Instance**: Sử dụng Spot instance cho 70% các tải tính toán môi trường Test, mang lại mức giảm giá ~70% so với giá On-Demand.
4. **Compute Savings Plans**: Áp dụng Compute Savings Plans 3 năm cho các node EKS Production baseline, giảm 35-40% chi phí EC2 baseline.
5. **Lưu trữ Vòng đời Log**: Chuyển tiếp luồng log thô container qua Fluent Bit sang S3 Standard, tự động chuyển sang S3 Glacier Flexible Retrieval sau 30 ngày (`ADR-012`), giảm 80% chi phí lưu trữ log.
6. **Giới hạn Cấu hình Log Level ở Production**: Giới hạn log level microservice trên Production ở mức `INFO` và `WARN` để loại bỏ nhiễu log debug (`RSK-CST-002`).
7. **Tối ưu Lưu trữ EBS (`gp3`)**: Sử dụng volume lưu trữ `gp3` thay thế cho `gp2` legacy, mang lại chi phí thấp hơn 20% mỗi GB và tách biệt baseline IOPS.
8. **Giảm Lưu lượng Xuyên AZ**: Thực thi các quy tắc Kubernetes Topology Spread Constraints và định tuyến topology-aware (`topologyKeys`) để giữ các giao tiếp pod-to-pod trong cùng một AZ, tránh phí mạng $0.01/GB xuyên AZ (`RSK-003`).
9. **Single NAT Gateway cho Non-Production**: Cấp phát 1 NAT Gateway cho VPC Test thay vì 3 Multi-AZ NAT Gateways, tiết kiệm ~$65/tháng phí cố định non-prod.
10. **Caching ESO cho AWS Secrets Manager**: External Secrets Operator (ESO) được cấu hình với khoảng thời gian refresh 1 giờ để tránh các lượt gọi API Secrets Manager quá mức (`ADR-011`).
11. **Chính sách Bắt buộc Gắn Tag Tài nguyên AWS**: Thực thi các tag `CostCenter`, `Environment`, `BusinessSystem`, và `Owner` trên 100% tài nguyên AWS được cấp phát qua AWS Organizations SCPs (`CST-002`).
12. **Cảnh báo Ngân sách AWS Budgets & Bất thường Chi phí**: Cấu hình AWS Budgets gửi thông báo Slack/email khi đạt 85% dự báo ngân sách hàng tháng, và AWS Cost Anomaly Detection cảnh báo khi có đột biến chi tiêu hàng ngày vượt 20%.
