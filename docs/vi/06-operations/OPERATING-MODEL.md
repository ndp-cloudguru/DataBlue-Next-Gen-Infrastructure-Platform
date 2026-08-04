# Mô hình Vận hành: Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)

---

## 1. Tổng quan

Tài liệu này quy định quản trị vận hành, ma trận trách nhiệm RACI, và ranh giới miền cho **Nền tảng Hạ tầng Thế hệ mới DataBlue (DataBlue Next-Gen Infrastructure Platform)** (`datablue-nextgen-infra-platform`).

---

## 2. Ma trận Trách nhiệm Vận hành RACI

* **R**: Responsible (Thực thi công việc trực tiếp)
* **A**: Accountable (Ra quyết định và chịu trách nhiệm cao nhất)
* **C**: Consulted (Đóng góp ý kiến tư vấn)
* **I**: Informed (Được thông báo cập nhật)

| Miền Vận hành & Phạm vi Kỹ thuật | Đội Cloud Platform SRE & DevSecOps | Đội Quản trị Cơ sở Dữ liệu (DBA) | Đội Lập trình Ứng dụng (App Dev) | Đội Vận hành Doanh nghiệp (Ops) |
| :--- | :--- | :--- | :--- | :--- |
| **AWS Account Landing Zone & Subnets VPC** | **A / R** | Informed | Informed | Informed |
| **Control Plane EKS & Nodes Worker** | **A / R** | Informed | Informed | Informed |
| **Bảo mật IAM IRSA, KMS Keys & Kiểm toán** | **A / R** | Informed | Informed | Informed |
| **Stack Công cụ CI/CD Pipeline & ECR** | **A / R** | Informed | Consulted | Informed |
| **ArgoCD GitOps Releases & Manifests** | **A / R** | Informed | Consulted | Informed |
| **Vận hành Database (MySQL & DocumentDB)** | Consulted | **A / R** | Consulted | Informed |
| **Vận hành Cache & Queue (Redis & RabbitMQ)**| Consulted | **A / R** | Consulted | Informed |
| **Vận hành Nacos Service Discovery** | **A / R** | Consulted | Consulted | Informed |
| **Mã nguồn Ứng dụng & Spec Pod Microservice** | Consulted | Informed | **A / R** | Informed |
| **Prometheus, Grafana & Metrics APM** | **A / R** | Informed | Consulted | Consulted |
| **Logging Trung tâm (OpenSearch & S3)** | **A / R** | Informed | Informed | Informed |
| **Sao lưu & Snapshots Velero** | **A / R** | Consulted | Informed | Informed |
| **Chuyển vùng Khôi phục Thảm họa DR** | **A / R** | Consulted | Informed | Consulted |
| **Ứng cứu Sự cố 24/7 & Quy trình Thang cấp** | **A / R** | Consulted | Consulted | **R** |
