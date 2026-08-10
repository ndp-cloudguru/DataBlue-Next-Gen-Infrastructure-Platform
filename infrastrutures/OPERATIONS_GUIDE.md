# TÀI LIỆU VẬN HÀNH HỆ THỐNG MÔI TRƯỜNG TEST/UAT
**Dự án:** DataBlue AADD — AWS Infrastructure & Microservices  
**Khu vực (AWS Region):** `ap-southeast-1` (Singapore)  
**Tệp tài liệu:** `OPERATIONS_GUIDE.md`

---

## 1. Mô hình Kiến trúc & Tổng quan Môi trường Test

Hệ thống môi trường Test/UAT của DataBlue được thiết kế theo mô hình **Multi-Account AWS Architecture** nhằm tối ưu hóa bảo mật và phân vùng hạ tầng:

```
[ Account 4: datablue-test-entry (580857941574) ]
   └── Public NLB -> ECS Fargate Reverse Proxy (datablue-test-entry-proxy-service)
            │
            │ (VPC Peering - Phase 05)
            ▼
[ Account 1: datablue-test-core (580857941574) ]
   ├── Core VPC & Private Subnets
   ├── EKS Cluster (datablue-test-eks)
   │     └── Namespace: datablue-test
   │           ├── Nacos Baseline (nacos-service:8848)
   │           ├── Seata Distributed Tx (seata-server:8091)
   │           ├── Data-Checker Service
   │           └── 16 Microservices XianZhu (Gateway, Auth, User, Goods, Order, v.v.)
   ├── Data Layer (Private Subnets)
   │     ├── RDS MySQL (datablue-test-mysql)
   │     ├── ElastiCache Redis (datablue-test-redis)
   │     └── Amazon MQ RabbitMQ
   └── ECR Repository (datablue-test/backend-api)
```

---

## 2. Đăng nhập & Khởi tạo Kết nối Hạ tầng (Authentication & Login)

### 2.1. Đăng nhập & Kết nối Kubernetes CLI (`kubectl` -> EKS)
Thực hiện kết nối máy trạm vận hành tới EKS Cluster `datablue-test-eks`:

```bash
# 1. Cập nhật Kubeconfig kết nối EKS Cluster
aws eks update-kubeconfig \
  --name datablue-test-eks \
  --region ap-southeast-1

# 2. Kiểm tra thông tin Caller Identity hiện tại
aws sts get-caller-identity

# 3. (Nếu bị lỗi thiếu quyền Access Entry) Thêm IAM Role/User hiện tại vào EKS Access Entry:
aws eks create-access-entry \
  --cluster-name datablue-test-eks \
  --principal-arn arn:aws:iam::580857941574:root \
  --region ap-southeast-1

# 4. Gán quyền Cluster Admin cho Principal:
aws eks associate-access-policy \
  --cluster-name datablue-test-eks \
  --principal-arn arn:aws:iam::580857941574:root \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region ap-southeast-1

# 5. Xác nhận kết nối thành công:
kubectl get nodes
```

### 2.2. Đăng nhập Container Registry (AWS ECR Login)
Đăng nhập Docker client để push/pull image từ ECR Repository của Account Core:

```bash
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin 580857941574.dkr.ecr.ap-southeast-1.amazonaws.com
```

---

## 3. Giám sát & Liệt kê Tài nguyên Kubernetes (List & Inspect)

Tất cả các câu lệnh bên dưới thực thi trên namespace `datablue-test`:

### 3.1. Liệt kê Pods (List Pods)
```bash
# Xem danh sách tất cả Pods kèm IP và Node phân bổ
kubectl get pods -n datablue-test -o wide

# Lọc các Pods bị lỗi (ImagePullBackOff, CrashLoopBackOff, Error)
kubectl get pods -n datablue-test --field-selector=status.phase!=Running

# Xem mức độ tiêu thụ CPU / RAM của từng Pod
kubectl top pods -n datablue-test
```

### 3.2. Liệt kê Services & Ports (List Services)
```bash
# Xem danh sách ClusterIP Services và Cổng (Port) Mapping
kubectl get svc -n datablue-test

# Xem chi tiết thông tin IP / Endpoints của 1 Service
kubectl get endpoints -n datablue-test
```

### 3.3. Liệt kê Deployments (List Deployments)
```bash
# Xem trạng thái sẵn sàng (Ready/Up-to-date/Available) của các Deployments
kubectl get deploy -n datablue-test
```

### 3.4. Xem Log & Inspect Chi tiết (Logs & Describe)
```bash
# Xem 100 dòng log gần nhất và theo dõi thời gian thực của 1 microservice
kubectl logs -n datablue-test -l app=xianzhu-gateway --tail=100 -f

# Xem log của Pod khi bị Crash (Log của lần crash trước đó)
kubectl logs -n datablue-test <pod-name> --previous

# Xem Sự kiện (Events) và lý do Pod không khởi chạy thành công
kubectl describe pod <pod-name> -n datablue-test

# Xem thông tin chi tiết cấu hình Deployment
kubectl describe deployment xianzhu-auth-service -n datablue-test
```

---

## 4. Khởi tạo & Tạo mới Tài nguyên (Create Services & Manifests)

### 4.1. Sinh tự động & Triển khai toàn bộ Manifests K8s
Repository tích hợp script tự động tạo file manifest [k8s-manifest.yaml](file:///Volumes/Data/WorkSpace/datablue-aadd-terraform/apps/xianzhu/k8s-manifest.yaml) đã chuẩn hóa cổng service:

```bash
# 1. Sinh file manifest chuẩn hóa ports
python3 -c "import sys, os; sys.path.insert(0, 'scripts'); import importlib.util; spec = importlib.util.spec_from_file_location('build_all', 'scripts/build-all-xianzhu.py'); module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module); module.generate_manifests()"

# 2. Triển khai (Apply) toàn bộ 16 microservices & ExternalName Services
kubectl apply -f apps/xianzhu/k8s-manifest.yaml
```

### 4.2. Tạo mới / Deploy thủ công một Microservice đơn lẻ
```bash
# Apply từ 1 file manifest riêng
kubectl apply -f path/to/service-manifest.yaml -n datablue-test
```

---

## 5. Cập nhật & Restart Dịch vụ (Update & Rollout Restart)

### 5.1. Rolling Restart cập nhật dịch vụ (Zero-Downtime Restart)
```bash
# Restart 1 Microservice cụ thể (Ví dụ: gateway)
kubectl rollout restart deployment/xianzhu-gateway -n datablue-test

# Restart toàn bộ 16 Microservices XianZhu cùng lúc
kubectl rollout restart deployment -n datablue-test -l 'app>=xianzhu'

# Theo dõi tiến trình Rollout Restart
kubectl rollout status deployment/xianzhu-gateway -n datablue-test
```

### 5.2. Cập nhật Image Tag của Deployment
```bash
kubectl set image deployment/xianzhu-goods-service \
  goods-service=580857941574.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-test/backend-api:goods-service-v2 \
  -n datablue-test
```

---

## 6. Xóa & Dọn dẹp Tài nguyên Kubernetes (Delete Resources)

### 6.1. Xóa toàn bộ 16 Microservices XianZhu theo Manifest
Lệnh này xóa toàn bộ Deployments và Services của nhóm XianZhu mà không ảnh hưởng tới Nacos/Seata:

```bash
kubectl delete -f apps/xianzhu/k8s-manifest.yaml --ignore-not-found=true
```

### 6.2. Xóa một Deployment hoặc Service cụ thể
```bash
# Xóa Deployment của 1 service
kubectl delete deployment xianzhu-auth-service -n datablue-test

# Xóa Service của 1 service
kubectl delete service xianzhu-auth-service-service -n datablue-test
```

### 6.3. Xóa / Khởi động lại một Pod bị lỗi (Force Re-create Pod)
Khi xóa Pod, Deployment controller sẽ tự động tạo một Pod mới thay thế ngay lập tức:

```bash
# Xóa Pod bình thường
kubectl delete pod <pod-name> -n datablue-test

# Xóa ép (Force Delete) khi Pod bị treo trạng thái Terminating
kubectl delete pod <pod-name> -n datablue-test --force --grace-period=0
```

---

## 7. Bảng Tra Cứu Cổng Listen (Port Reference Table - 16 Microservices)

Tất cả 16 microservices được cấu hình cổng lắng nghe thực tế chuẩn xác khớp với tệp `bootstrap.yml` mã nguồn:

| Service Name | K8s Deployment Name | K8s Service Name | Container & Service Port |
| :--- | :--- | :--- | :---: |
| **`gateway`** | `xianzhu-gateway` | `xianzhu-gateway-service` | **`8888`** |
| **`auth-service`** | `xianzhu-auth-service` | `xianzhu-auth-service-service` | **`11100`** |
| **`broadcast-service`** | `xianzhu-broadcast-service` | `xianzhu-broadcast-service-service` | **`11111`** |
| **`distribution-service`** | `xianzhu-distribution-service` | `xianzhu-distribution-service-service` | **`11112`** |
| **`goods-service`** | `xianzhu-goods-service` | `xianzhu-goods-service-service` | **`11113`** |
| **`user-service`** | `xianzhu-user-service` | `xianzhu-user-service-service` | **`11114`** |
| **`order-service`** | `xianzhu-order-service` | `xianzhu-order-service-service` | **`11115`** |
| **`payment-service`** | `xianzhu-payment-service` | `xianzhu-payment-service-service` | **`11116`** |
| **`promotion-service`** | `xianzhu-promotion-service` | `xianzhu-promotion-service-service` | **`11117`** |
| **`statistics-service`** | `xianzhu-statistics-service` | `xianzhu-statistics-service-service` | **`11118`** |
| **`system-service`** | `xianzhu-system-service` | `xianzhu-system-service-service` | **`11119`** |
| **`resource-service`** | `xianzhu-resource-service` | `xianzhu-resource-service-service` | **`11120`** |
| **`supplier-service`** | `xianzhu-supplier-service` | `xianzhu-supplier-service-service` | **`11121`** |
| **`xianzhu-service`** | `xianzhu-xianzhu-service` | `xianzhu-xianzhu-service-service` | **`11122`** |
| **`im-service`** | `xianzhu-im-service` | `xianzhu-im-service-service` | **`11130`** |
| **`consumer`** | `xianzhu-consumer` | `xianzhu-consumer-service` | **`12000`** |

---

## 8. Quản lý Middleware & Data Layer Services

### 8.1. Nacos Cluster Service (`nacos-service:8848`)
- **Check danh sách service đã đăng ký Nacos:**
  ```bash
  python3 scripts/check-nacos-services.py
  ```
- **Sync Nacos Configurations:**
  ```bash
  python3 apps/xianzhu/publish-nacos-config.py
  ```

### 8.2. ExternalName Services kết nối Data Layer
- **MySQL RDS Endpoint:** `datablue-test-mysql.cdw6qg4eg8qw.ap-southeast-1.rds.amazonaws.com` (Port 3306)
- **Redis ElastiCache Endpoint:** `master.datablue-test-redis.ihjx1q.apse1.cache.amazonaws.com` (Port 6379)
- **RabbitMQ Broker Endpoint:** `b-fb078dff-6d79-4f3e-b997-08445dd7b3d5.mq.ap-southeast-1.on.aws` (Port 5671)

---

## 9. Sổ Tay Xử Lý Sự Cố (Troubleshooting Runbook)

| Hiện tượng / Lỗi | Nguyên nhân | Thao tác khắc phục |
| :--- | :--- | :--- |
| **`UnrecognizedClientException`** | AWS Profile / Access key hết hạn | Bỏ tham số `--profile` hoặc cấp lại access key mới trong `~/.aws/credentials`. |
| **`You must be logged in to the server`** | Principal chưa được cấp quyền EKS Access Entry | Chạy lệnh `aws eks create-access-entry` và `associate-access-policy` với policy `AmazonEKSClusterAdminPolicy`. |
| **`ImagePullBackOff` / `ErrImagePull`** | Tag image chưa có trên ECR hoặc hết hạn token docker login | Chạy lệnh ECR Login `aws ecr get-login-password ... \| docker login ...` và kiểm tra tag trên ECR. |
| **`CrashLoopBackOff`** | Lỗi ứng dụng (Nacos config, DB connection, thiếu RAM) | Chạy `kubectl logs -n datablue-test <pod-name> --previous` để đọc stack trace lỗi Java. |
| **Pod đứng yên không khởi chạy** | Thiếu tài nguyên Node (CPU/RAM) | Chạy `kubectl describe pod <pod-name> -n datablue-test` kiểm tra sự kiện Scheduler. |

---
*Tài liệu được cập nhật tự động toàn bộ quy trình vận hành Kubernetes (Login, List, Create, Update, Delete) cho dự án DataBlue AADD.*
