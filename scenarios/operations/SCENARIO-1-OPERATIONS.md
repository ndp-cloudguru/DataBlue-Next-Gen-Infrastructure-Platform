# Scenario 1 Operational Runbook: Standard Non-Production Test Baseline

**Project Identifier**: `datablue-nextgen-infra-platform`  
**Target Environment**: Test / UAT (`DataBlue-Test-Account`)  
**Target Monthly Budget**: 💰 `$362.03 / month` (`$362 – $500 / month`)  
**AWS Region**: Singapore (`ap-southeast-1`)  
**Governance Standard**: Architecture-First Governance Standard (`OPERATING-MODEL.md` & `TERRAFORM_TEST_PLANNING.md`)

---

## 1. Architecture Diagram & Infrastructure Topology

Scenario 1 implements a cost-optimized 2-Availability-Zone (`ap-southeast-1a`, `ap-southeast-1b`) non-production test baseline topology across Account 1 (Test Core) and Account 4 (Test Entry) connected via Direct VPC Peering (bypassing Transit Gateway to save $173/month):

```mermaid
graph TD
    classDef testEntryFill fill:#e8f5e9,stroke:#388e3c,stroke-width:2px,color:#1b5e20;
    classDef testCoreFill fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:#01579b;
    classDef edgeFill fill:#eceff1,stroke:#455a64,stroke-width:2px;

    Tester["👨‍💻 Internal QA / Testers"] -->|Test Traffic| NLB["Public NLB (DataBlue-Test-Entry-NLB)"]

    subgraph EdgeLayer ["🌐 Public Traffic Entry Layer"]
        NLB
    end

    subgraph Account4 ["🟢 AWS Account 4: Internal Test Public Entry"]
        subgraph TestEntryVPC ["VPC Test Entry (10.40.0.0/16)"]
            NLB --> FARGATE["ECS Fargate Test Proxy<br/>(1 vCPU / 2GB Task)"]
        end
    end

    subgraph Account1 ["🔴 AWS Account 1: Test Core Environment"]
        subgraph TestCoreVPC ["🔸 Test Core VPC (10.50.0.0/16 - DETACHED FROM TGW)"]
            TEST_EKS["Amazon EKS Test Cluster<br/>(DataBlue-Test-EKS: 2x t4g.medium Worker Nodes)"]
            TEST_NACOS["Nacos Service Discovery<br/>(ClusterIP / NodePort)"]
            TEST_ECR["Amazon ECR Registry<br/>(KMS Encrypted & Image Scanning)"]
            TEST_RDS[("RDS MySQL Test Single-AZ<br/>datablue-test-mysql db.t4g.medium 100GB GP3")]
            TEST_REDIS[("ElastiCache Redis Test<br/>datablue-test-redis cache.t4g.small")]
            TEST_MQ["Amazon MQ RabbitMQ Test<br/>datablue-test-rabbitmq mq.t3.micro"]

            TEST_EKS --> TEST_NACOS
            TEST_EKS --> TEST_ECR
            TEST_EKS --> TEST_RDS
            TEST_EKS --> TEST_REDIS
            TEST_EKS --> TEST_MQ
            TEST_NACOS --> TEST_RDS
        end
    end

    %% Direct VPC Peering connection bypassing Transit Gateway
    FARGATE <== "DIRECT VPC PEERING (FREE Hourly Fee - Bypasses TGW)" ==> TEST_EKS

    class Account4 testEntryFill;
    class Account1 testCoreFill;
    class EdgeLayer edgeFill;
```

### Resource Specification Matrix

| Hạng mục Dịch vụ | Thành phần Hạ tầng | Cấu hình Chi tiết / Identifier | Số lượng | vCPU / RAM | Chi phí Hàng tháng | Ghi chú Tối ưu & Thiết lập Kỹ thuật |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **Networking** | **Account 1: Test Core VPC** | `10.50.0.0/16` | 1 VPC | - | $43.07 | 2-AZ (`ap-southeast-1a/b`), Public, Private App, DB Subnets |
| **Networking** | **Account 4: Test Entry VPC** | `10.40.0.0/16` | 1 VPC | - | $0.00 | Public Subnets & Private App Subnets |
| **Networking** | **VPC Peering Trực tiếp** | `aws_vpc_peering_connection` | 1 Connection | - | **$0.00** | **Tách khỏi Transit Gateway** (Tiết kiệm $173/tháng phí TGW!) |
| **Security** | **AWS KMS Key** | Customer Managed Key (CMK) | 1 Key | - | $3.00 | Mã hóa tĩnh At-Rest cho RDS, EKS, ECR, Secrets Manager & S3 |
| **Registry** | **Amazon ECR** | `datablue-test/*` Repositories | 3 Repos | - | Free Tier / Pay-per-GB | Scan on push, KMS Encrypted, Lifecycle 10 images |
| **Compute** | **Amazon EKS Cluster** | `DataBlue-Test-EKS` | 1 Cluster | AWS Managed | $73.00 | Kubernetes v1.30 Control Plane Standard Support |
| **Compute** | **EKS Worker Node Group** | `t4g.medium` (ARM64 Graviton) | 2 Nodes | 2 vCPU / 4 GiB | $63.25 | On-Demand/Spot nodes (`desired: 2`, `min: 2`, `max: 4`) |
| **Registry / Config**| **Nacos Service** | `nacos-server` | 1 Pod | Shared EKS | $0.00 | Registered on EKS with MySQL RDS Backend |
| **Database** | **Amazon RDS MySQL** | `datablue-test-mysql` | 1 Instance | 2 vCPU / 4 GiB | $90.00 | `db.t4g.medium` Single-AZ + 100GB đĩa GP3 ($14.50) |
| **Cache** | **ElastiCache Redis** | `datablue-test-redis` | 1 Node | 2 vCPU / 1.37 GiB | $35.00 | `cache.t4g.small` Single Node Cluster |
| **Messaging** | **Amazon MQ RabbitMQ** | `datablue-test-rabbitmq` | 1 Broker | 2 vCPU / 1 GiB | $20.00 | `mq.t3.micro` Single Instance Broker |
| **Entry Proxy** | **Public NLB + Fargate** | `DataBlue-Test-Entry-NLB` | 1 NLB | 1 vCPU / 2 GiB | $55.00 | Fargate Proxy Task + Public Network Load Balancer |
| **TỔNG CỘNG** | **MÔI TRƯỜNG TEST** | **Test Core & Test Entry** | **12 Tài nguyên** | **8 vCPU / 16 GiB** | 💰 **$362.03/tháng** | **Cấu hình tối ưu chi phí cho môi trường Test** |

### 1.2 Cấu trúc Mã nguồn Hạ tầng Terraform (Terraform Codebase Structure)

Mã nguồn Terraform được tổ chức theo mô hình **Modular Architecture (Kiến trúc Module hóa tái sử dụng)** kết hợp với **Environment Scenarios Root**:

```text
scenarios/
├── modules/                                # 📦 THƯ MỤC MODULES TÁI SỬ DỤNG (REUSABLE MODULES)
│   ├── amazon_mq_rabbitmq/                 # Module Amazon MQ RabbitMQ Broker
│   │   ├── main.tf, variables.tf, outputs.tf
│   ├── documentdb/                         # Module DocumentDB Cluster
│   │   ├── main.tf, variables.tf, outputs.tf
│   ├── ecr/                                # Module Amazon ECR Container Registry (KMS & Scanning)
│   │   ├── main.tf, variables.tf, outputs.tf
│   ├── eks/                                # Module Amazon EKS Cluster & Worker NodeGroup
│   │   ├── main.tf, variables.tf, outputs.tf
│   ├── elasticache_redis/                  # Module ElastiCache Redis Replication Group
│   │   ├── main.tf, variables.tf, outputs.tf
│   ├── kms/                                # Module AWS KMS Customer Managed Key (CMK)
│   │   ├── main.tf, variables.tf, outputs.tf
│   ├── opensearch/                         # Module OpenSearch Cluster
│   │   ├── main.tf, variables.tf, outputs.tf
│   ├── rds_mysql/                          # Module RDS MySQL Instance
│   │   ├── main.tf, variables.tf, outputs.tf
│   └── vpc/                                # Module VPC Networking (Subnets, NAT, Route Tables)
│       ├── main.tf, variables.tf, outputs.tf
│
└── scenario-1-test-baseline/               # 🚀 ROOT MODULE MÔI TRƯỜNG TEST BASELINE (ap-southeast-1)
    ├── main.tf                             # Orchestration chính, ghép nối các Module & Dual AWS Providers
    ├── variables.tf                        # Khai báo biến đầu vào (CIDRs, AWS Profiles, CPU/Memory)
    ├── outputs.tf                          # Xuất Endpoints, ARNs, NLB DNS & ECR URLs
    └── terraform.tfvars                    # Giá trị biến thực tế theo môi trường
```

---

## 2. Pre-Deployment Prerequisites & Environment Setup

### 2.1 Công cụ cần thiết (Required CLI Tools)
```bash
# Kiểm tra các công cụ yêu cầu
terraform version   # Yêu cầu >= 1.7.0
aws --version       # Yêu cầu >= 2.15.0
kubectl version     # Yêu cầu >= 1.30.0
helm version        # Yêu cầu >= 3.12.0
docker --version    # Container image builder
```

### 2.2 Thiết lập và Lưu trữ Nhiều AWS Credentials (Multi-Account Profile Setup)

Hạ tầng Scenario 1 triển khai trên 2 AWS Account riêng biệt (Account 1: Test Core & Account 4: Test Entry). Bạn cần cấu hình 2 AWS Profile trong `~/.aws/credentials` hoặc `~/.aws/config`:

#### Cách 1: Sử dụng AWS Access Key / Secret Key (`~/.aws/credentials`)
Tạo hoặc bổ sung vào file `~/.aws/credentials`:
```ini
[datablue-test-core]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
region = ap-southeast-1

[datablue-test-entry]
aws_access_key_id = AKIAYYYYYYYYYYYYYYYY
aws_secret_access_key = yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
region = ap-southeast-1
```

#### Cách 2: Sử dụng AWS SSO (Single Sign-On - `~/.aws/config`)
Tạo hoặc bổ sung vào file `~/.aws/config`:
```ini
[profile datablue-test-core]
sso_start_url = https://datablue.awsapps.com/start
sso_region = ap-southeast-1
sso_account_id = 111111111111
sso_role_name = AWSAdministratorAccess
region = ap-southeast-1

[profile datablue-test-entry]
sso_start_url = https://datablue.awsapps.com/start
sso_region = ap-southeast-1
sso_account_id = 444444444444
sso_role_name = AWSAdministratorAccess
region = ap-southeast-1
```

#### 📌 Đăng nhập & Xác nhận Identities trước khi chạy Terraform
```bash
# 1. Đăng nhập SSO (nếu sử dụng SSO)
aws sso login --profile datablue-test-core
aws sso login --profile datablue-test-entry

# 2. Thiết lập các biến môi trường cấu hình chính
export AWS_REGION="ap-southeast-1"
export TERRAFORM_CODE_PATH="scenarios/scenario-1-test-baseline"

# 3. Kiểm tra và đối soát Identity của cả 2 Account
aws sts get-caller-identity --profile datablue-test-core
aws sts get-caller-identity --profile datablue-test-entry

# 4. Lấy Account ID của Account Core để sử dụng cho ECR / EKS
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile datablue-test-core --query "Account" --output text)
```

### 2.3 Kiểm tra AWS Service Quotas & Đối chiếu Yêu cầu Hạ tầng Scenario 1

Trước khi thực thi `terraform apply`, thực hiện đối chiếu Service Quotas để đảm bảo tài khoản có đủ tài nguyên khởi tạo.

#### Option 1: Chạy Script Tự động Kiểm tra & Báo cáo Quotas (Khuyên dùng)
```bash
./scenarios/operations/scripts/check_aws_quotas.sh --scenario 1 --profile datablue-test-core --region ap-southeast-1
```

#### Option 2: Kiểm tra thủ công bằng AWS CLI
```bash
# 1. Kiểm tra Quota vCPU On-Demand Standard (Yêu cầu >= 4 vCPUs cho 2x t4g.medium EKS Worker Nodes)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region ap-southeast-1 \
  --profile datablue-test-core \
  --query "Quota.[QuotaName, Value]"

# 2. Kiểm tra Quota Elastic IP (Yêu cầu 1-2 EIPs cho NAT Gateways)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --region ap-southeast-1 \
  --profile datablue-test-core \
  --query "Quota.[QuotaName, Value]"

# 3. Kiểm tra Quota VPCs per Region (Yêu cầu 1 VPC cho Test Core & 1 VPC cho Test Entry)
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-F678F1CE \
  --region ap-southeast-1 \
  --profile datablue-test-core \
  --query "Quota.[QuotaName, Value]"
```

#### 📊 Bảng Đối chiếu Quota Hạn Ngạch & Nhu cầu Hạ tầng Scenario 1

| Dịch vụ AWS | Mã Quota Code | Yêu cầu Scenario 1 (Required) | Hạn ngạch Mặc định | Đánh giá Khả thi |
| :--- | :--- | :---: | :---: | :---: |
| **EC2 On-Demand Standard vCPUs** | `L-1216C47A` | **4 vCPUs** (2x t4g.medium) | 8.0 – 32.0 vCPUs | ✅ Đạt |
| **Elastic IP (EIP)** | `L-0263D0A3` | **1 - 2 EIPs** (NAT Gateways) | 5 EIPs | ✅ Đạt |
| **VPCs per Region** | `L-F678F1CE` | **1 VPC** / Account | 5 VPCs | ✅ Đạt |

---

## 3. Infrastructure Provisioning & Real-Time Monitoring

### 3.1 Khởi tạo và Triển khai Hạ tầng bằng Terraform
```bash
# 1. Chuyển vào thư mục chứa mã nguồn Terraform
cd ${TERRAFORM_CODE_PATH}

# 2. Khởi tạo S3 Bucket & DynamoDB Lock Table (Thực hiện nếu chưa có sẵn Backend S3)
aws s3api create-bucket \
  --bucket datablue-tfstate-ap-southeast-1 \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1 \
  --profile datablue-test-core

aws s3api put-bucket-versioning \
  --bucket datablue-tfstate-ap-southeast-1 \
  --versioning-configuration Status=Enabled \
  --profile datablue-test-core

aws s3api put-bucket-encryption \
  --bucket datablue-tfstate-ap-southeast-1 \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile datablue-test-core

aws s3api put-public-access-block \
  --bucket datablue-tfstate-ap-southeast-1 \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile datablue-test-core

aws dynamodb create-table \
  --table-name datablue-test-tflocks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1 \
  --profile datablue-test-core

# 3. Khởi tạo Terraform & Backend (S3 + DynamoDB Lock)
terraform init \
  -backend-config="bucket=datablue-tfstate-ap-southeast-1" \
  -backend-config="key=env/test/terraform.tfstate" \
  -backend-config="region=ap-southeast-1" \
  -backend-config="dynamodb_table=datablue-test-tflocks"

# 4. Kiểm tra cú pháp và tính hợp lệ của HCL
terraform validate

# 5. Tự động định dạng lại code
terraform fmt

# 6. Xem trước kế hoạch thay đổi hạ tầng
terraform plan -out=tfplan-test

# 7. Triển khai hạ tầng (sau khi kế hoạch được phê duyệt)
terraform apply tfplan-test
```

### 3.2 Lệnh Giám sát & Check Trạng thái trong khi Triển khai (Terraform & AWS Monitoring)
```bash
# A. Kiểm tra State và Lock Status trên S3 / DynamoDB
aws s3 ls s3://datablue-tfstate-ap-southeast-1/env/test/
aws dynamodb get-item \
  --table-name datablue-test-tflocks \
  --key '{"LockID": {"S": "datablue-tfstate-ap-southeast-1/env/test/terraform.tfstate-md5"}}'

# B. Kiểm tra danh sách tài nguyên đã tạo trong State File
terraform state list

# C. Theo dõi tiến độ tạo EKS Cluster (Real-time Status Check)
watch -n 5 "aws eks describe-cluster --name DataBlue-Test-EKS --region ap-southeast-1 --query 'cluster.status'"

# D. Theo dõi trạng thái khởi tạo RDS Instance
watch -n 5 "aws rds describe-db-instances --db-instance-identifier datablue-test-mysql --region ap-southeast-1 --query 'DBInstances[0].[DBInstanceStatus, Endpoint.Address]'"

# E. Kiểm tra trạng thái ElastiCache Redis Replication Group
aws elasticache describe-replication-groups \
  --replication-group-id datablue-test-redis \
  --region ap-southeast-1 \
  --query "ReplicationGroups[0].[Status, NodeGroups[0].PrimaryEndpoint.Address]"

# F. Kiểm tra trạng thái Amazon MQ RabbitMQ Broker
aws mq list-brokers --region ap-southeast-1

# G. Kiểm tra ECS Fargate Proxy Deployment Status (Account 4)
aws ecs describe-services \
  --cluster DataBlue-Test-Entry-ECS-Cluster \
  --services DataBlue-Test-Entry-Proxy-Service \
  --region ap-southeast-1 \
  --query "services[0].[status, runningCount, pendingCount]"

# H. Xem tất cả Outputs đã tạo (Bao gồm ECR Repositories)
terraform output
```

### 3.3 Kết quả Terraform Outputs & Đối soát Sơ đồ Kiến trúc (Expected Outputs & Architecture Mapping)

Sau khi thực hiện `terraform apply` thành công, màn hình sẽ trả về bộ **Outputs chuẩn**. Bộ thông tin này khớp 100% với **Sơ đồ Kiến trúc (Section 1)** và được dùng làm tham số cấu hình cho các bước vận hành tiếp theo:

```hcl
Outputs:

ecr_repository_urls = {
  "datablue-test/backend-api" = "111111111111.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-test/backend-api"
  "datablue-test/envoy-proxy" = "111111111111.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-test/envoy-proxy"
  "datablue-test/frontend"    = "111111111111.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-test/frontend"
}
ecs_fargate_proxy_cluster_name    = "DataBlue-Test-Entry-ECS-Cluster"
ecs_fargate_proxy_service_name    = "DataBlue-Test-Entry-Proxy-Service"
ecs_fargate_proxy_task_definition = "arn:aws:ecs:ap-southeast-1:444444444444:task-definition/datablue-test-proxy-task:1"
eks_cluster_endpoint             = "https://ACC123456789.gr7.ap-southeast-1.eks.amazonaws.com"
eks_cluster_name                 = "DataBlue-Test-EKS"
kms_key_arn                      = "arn:aws:kms:ap-southeast-1:111111111111:key/12345678-1234-1234-1234-123456789012"
rabbitmq_amqp_endpoints          = [
  "amqps://b-12345678-1.mq.ap-southeast-1.amazonaws.com:5671"
]
rds_mysql_endpoint               = "datablue-test-mysql.c123456789.ap-southeast-1.rds.amazonaws.com:3306"
rds_mysql_secret_name            = "datablue/test/rds-mysql"
rds_mysql_secret_arn             = "arn:aws:secretsmanager:ap-southeast-1:111111111111:secret:datablue/test/rds-mysql-123456"
redis_primary_endpoint           = "datablue-test-redis.123456.ng.001.apse1.cache.amazonaws.com"

# Network VPC & Subnet Layer Outputs
test_core_vpc_id                 = "vpc-0a1b2c3d4e5f67890"
test_core_public_subnet_ids      = [
  "subnet-0public11111111111", # 10.50.1.0/24 (ap-southeast-1a)
  "subnet-0public22222222222"  # 10.50.2.0/24 (ap-southeast-1b)
]
test_core_private_app_subnet_ids = [
  "subnet-0privateapp1111111", # 10.50.10.0/24 (ap-southeast-1a)
  "subnet-0privateapp2222222"  # 10.50.20.0/24 (ap-southeast-1b)
]
test_core_database_subnet_ids    = [
  "subnet-0database111111111", # 10.50.100.0/24 (ap-southeast-1a)
  "subnet-0database222222222"  # 10.50.200.0/24 (ap-southeast-1b)
]

test_entry_vpc_id                = "vpc-0f9e8d7c6b5a43210"
test_entry_public_subnet_ids     = [
  "subnet-0entrypub111111111", # 10.40.1.0/24 (ap-southeast-1a)
  "subnet-0entrypub222222222"  # 10.40.2.0/24 (ap-southeast-1b)
]
test_entry_private_app_subnet_ids= [
  "subnet-0entryapp111111111", # 10.40.10.0/24 (ap-southeast-1a)
  "subnet-0entryapp222222222"  # 10.40.20.0/24 (ap-southeast-1b)
]

test_entry_nlb_dns_name          = "DataBlue-Test-Entry-NLB-12345678.elb.ap-southeast-1.amazonaws.com"
vpc_peering_connection_id        = "pcx-0123456789abcdef0"
```

#### 📊 Bảng Đối soát Output với Sơ đồ Kiến trúc & Hạng mục Vận hành

| Tên Output Terraform | Ý nghĩa & Vị trí trên Sơ đồ Kiến trúc | Dùng cho Bước Vận hành Nào? |
| :--- | :--- | :--- |
| **`test_core_vpc_id`** | Account 1 Test Core VPC (`10.50.0.0/16`) | Kiểm tra mạng nội bộ & Route Tables (`Section 3.2`) |
| **`test_core_public_subnet_ids`** | Lớp Public Subnets Core (`10.50.1.0/24`, `10.50.2.0/24`) | Nơi đặt Public NAT Gateway cho EKS Nodes ra Internet |
| **`test_core_private_app_subnet_ids`** | Lớp Private App Subnets Core (`10.50.10.0/24`, `10.50.20.0/24`) | Nơi đặt EKS Worker Nodes, Nacos Pods & ArgoCD |
| **`test_core_database_subnet_ids`** | Lớp Isolated DB Subnets Core (`10.50.100.0/24`, `10.50.200.0/24`) | Nơi đặt RDS MySQL, ElastiCache Redis & RabbitMQ |
| **`test_entry_vpc_id`** | Account 4 Test Entry VPC (`10.40.0.0/16`) | Kiểm tra Fargate Proxy Subnets & Security Groups |
| **`test_entry_public_subnet_ids`** | Lớp Public Subnets Entry (`10.40.1.0/24`, `10.40.2.0/24`) | Nơi đặt Public Network Load Balancer (NLB) |
| **`test_entry_private_app_subnet_ids`**| Lớp Private App Subnets Entry (`10.40.10.0/24`, `10.40.20.0/24`) | Nơi đặt ECS Fargate Proxy Task (Envoy Proxy) |
| **`vpc_peering_connection_id`** | Kết nối Direct VPC Peering giữa Account 4 & 1 | Network Connectivity Test (`Section 5.1`) |
| **`kms_key_arn`** | Key CMK mã hóa tĩnh At-Rest cho RDS/EKS/ECR | Kiểm tra Security & Audit compliance (`Section 6.1`) |
| **`eks_cluster_name` & `endpoint`** | Cluster Name & API Control Plane của EKS | Cấu hình `aws eks update-kubeconfig` (`Section 4.1`) |
| **`ecr_repository_urls`** | URLs của các Repositories Container Registry | Docker Login, Build & Push Microservices (`Section 4.3`) |
| **`rds_mysql_endpoint`** | Endpoint csdl RDS MySQL Single-AZ (`db.t4g.medium`) | Cấu hình Nacos (`Section 4.4`) & MySQL Test (`Section 5.3`) |
| **`redis_primary_endpoint`** | Primary Endpoint của ElastiCache Redis Cluster | Redis PING & Cache Verification (`Section 5.4`) |
| **`rabbitmq_amqp_endpoints`** | Endpoint AMQP (Port 5671) của Amazon MQ | RabbitMQ Connectivity Diagnostic (`Section 5.5`) |
| **`test_nlb_dns_name`** | DNS Public của Network Load Balancer (Account 4) | Kiểm thử E2E End-to-End Traffic (`Section 5.6`) |
| **`ecs_fargate_proxy_*`** | Cluster, Service & Task ARN của Envoy Proxy | Quản lý & Restart Fargate Proxy Task (`Section 4.6`) |

---

## 4. Service Deployment, ECR & ArgoCD GitOps Runbook

### 4.1 Kết nối và Cấu hình Kubernetes EKS
```bash
# Cập nhật kubeconfig local kết nối tới EKS Cluster
aws eks update-kubeconfig --region ap-southeast-1 --name DataBlue-Test-EKS

# Kiểm tra trạng thái Cluster và Worker Nodes
kubectl cluster-info
kubectl get nodes -o wide
```

### 4.2 Triển khai ArgoCD bằng Helm (GitOps Engine)
```bash
# 1. Thêm Helm Repository chính thức của Argo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 2. Tạo Namespace chuyên dụng cho ArgoCD
kubectl create namespace argocd

# 3. Cài đặt ArgoCD qua Helm Chart
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=ClusterIP \
  --set prometheus.enabled=true

# 4. Kiểm tra trạng thái Pods trong Namespace argocd
kubectl get pods -n argocd -o wide

# 5. Lấy mật khẩu quản trị ban đầu của ArgoCD (mật khẩu admin)
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: ${ARGOCD_PASSWORD}"

# 6. Mở Port-Forward để truy cập Web UI của ArgoCD tại local
# Truy cập: https://localhost:8080 (User: admin / Mật khẩu in ra ở trên)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 4.3 Quản lý Amazon ECR & Build/Push Docker Images

**Bước 1:** Đăng nhập vào ECR Registry
```bash
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com
```

**Bước 2:** Build, Tag và Push Image ứng dụng lên ECR
```bash
# Biến tên Image
REGISTRY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com"
IMAGE_TAG="v1.0.0"

# Build Image cho Backend Service
docker build -t datablue-test/backend-api:${IMAGE_TAG} ./backend
docker tag datablue-test/backend-api:${IMAGE_TAG} ${REGISTRY_URL}/datablue-test/backend-api:${IMAGE_TAG}
docker push ${REGISTRY_URL}/datablue-test/backend-api:${IMAGE_TAG}

# Build Image cho Frontend Service
docker build -t datablue-test/frontend:${IMAGE_TAG} ./frontend
docker tag datablue-test/frontend:${IMAGE_TAG} ${REGISTRY_URL}/datablue-test/frontend:${IMAGE_TAG}
docker push ${REGISTRY_URL}/datablue-test/frontend:${IMAGE_TAG}
```

**Bước 3:** Kiểm tra kết quả quét lỗ hổng bảo mật (Image Scan Findings)
```bash
aws ecr describe-image-scan-findings \
  --repository-name datablue-test/backend-api \
  --image-id imageTag=${IMAGE_TAG} \
  --region ap-southeast-1
```

### 4.4 Triển khai Nacos Service (Service Discovery & Naming Server)

**Bước 1:** Tạo Namespace `datablue-test`
```bash
kubectl create namespace datablue-test --dry-run=client -o yaml | kubectl apply -f -
```

**Bước 2:** Lấy thông tin RDS Endpoint & Master Password từ Terraform Output
```bash
RDS_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_endpoint | cut -d: -f1)
RDS_PASSWORD=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_master_password)
echo "RDS Endpoint: ${RDS_ENDPOINT}"
echo "RDS Password: ${RDS_PASSWORD}"
```

**Bước 3:** Tạo file manifest `nacos-deployment.yaml`

Lưu đoạn cấu hình sau vào file `nacos-deployment.yaml` (thay thế `YOUR_RDS_ENDPOINT` bằng giá trị `RDS_ENDPOINT` ở trên):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nacos-server
  namespace: datablue-test
  labels:
    app.kubernetes.io/name: nacos-server
    app.kubernetes.io/part-of: datablue-platform
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nacos-server
  template:
    metadata:
      labels:
        app: nacos-server
    spec:
      containers:
      - name: nacos
        image: nacos/nacos-server:v2.2.3
        env:
        - name: MODE
          value: "standalone"
        - name: SPRING_DATASOURCE_PLATFORM
          value: "mysql"
        - name: MYSQL_SERVICE_HOST
          value: "YOUR_RDS_ENDPOINT"
        - name: MYSQL_SERVICE_PORT
          value: "3306"
        - name: MYSQL_SERVICE_DB_NAME
          value: "datablue_test_db"
        - name: MYSQL_SERVICE_USER
          value: "admin_test"
        - name: MYSQL_SERVICE_PASSWORD
          value: "MasterPassword123!"
        ports:
        - containerPort: 8848
          name: client-port
        - containerPort: 9848
          name: client-grpc
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1024Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /nacos/actuator/health
            port: 8848
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /nacos/actuator/health
            port: 8848
          initialDelaySeconds: 60
          periodSeconds: 15
---
apiVersion: v1
kind: Service
metadata:
  name: nacos-service
  namespace: datablue-test
  labels:
    app.kubernetes.io/name: nacos-service
spec:
  type: ClusterIP
  selector:
    app: nacos-server
  ports:
  - name: http
    port: 8848
    targetPort: 8848
  - name: grpc
    port: 9848
    targetPort: 9848
```

**Bước 4:** Thực thi triển khai Nacos Server

```bash
kubectl apply -f nacos-deployment.yaml

# Kiểm tra trạng thái Deployment và Pods
kubectl get pods -l app=nacos-server -n datablue-test -w
```

### 4.5 Triển khai App thử nghiệm bằng ArgoCD Application Manifest

**Bước 1:** Tạo file manifest `argocd-app.yaml`

Lưu cấu hình dưới đây vào file `argocd-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: datablue-test-services
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/datablue/k8s-manifests.git'
    targetRevision: HEAD
    path: environments/test
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: datablue-test
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

**Bước 2:** Thực thi áp dụng Manifest

```bash
kubectl apply -f argocd-app.yaml

# Kiểm tra trạng thái ứng dụng trên ArgoCD
kubectl get application -n argocd
```

### 4.6 Quản lý ECS Fargate Proxy (Account 4 Test Entry)
```bash
# Xem trạng thái ECS Cluster và Service Fargate Proxy
aws ecs describe-clusters --clusters DataBlue-Test-Entry-ECS-Cluster --region ap-southeast-1
aws ecs list-services --cluster DataBlue-Test-Entry-ECS-Cluster --region ap-southeast-1

# Force Deploy / Restart Fargate Proxy Task khi có cập nhật cấu hình Envoy
aws ecs update-service \
  --cluster DataBlue-Test-Entry-ECS-Cluster \
  --service DataBlue-Test-Entry-Proxy-Service \
  --force-new-deployment \
  --region ap-southeast-1

# View Fargate Task Logs từ CloudWatch
aws logs tail /ecs/DataBlue-Test-Proxy --follow --region ap-southeast-1
```

---

## 5. Comprehensive Testing & Verification Suite (Các kịch bản Kiểm thử)

### 5.1 Kiểm thử Kết nối Mạng & VPC Peering (Network Connectivity Test)
```bash
# 1. Kiểm tra trạng thái Active của VPC Peering Connection
PEERING_ID=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw vpc_peering_connection_id)
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids ${PEERING_ID} \
  --query "VpcPeeringConnections[0].Status.Code" \
  --region ap-southeast-1

# 2. Kiểm tra phân giải DNS và mạng nội bộ từ Pod
kubectl run network-diag --rm -i --tty --image=busybox:1.36 --namespace=datablue-test -- restart=Never -- nslookup kubernetes.default
```

### 5.2 Kiểm thử Nacos Service Discovery & Naming API (Nacos Test)
```bash
# 1. Kiểm tra Health Check Endpoint của Nacos Server
kubectl run nacos-health-test --rm -i --tty --image=curlimages/curl:8.5.0 --namespace=datablue-test -- \
  curl -s "http://nacos-service.datablue-test.svc.cluster.local:8848/nacos/actuator/health"

# 2. Kiểm tra Đăng ký Service Mẫu vào Nacos Instance (Register Service Test)
kubectl run nacos-reg-test --rm -i --tty --image=curlimages/curl:8.5.0 --namespace=datablue-test -- \
  curl -X POST "http://nacos-service.datablue-test.svc.cluster.local:8848/nacos/v1/ns/instance?serviceName=test.service&ip=10.50.10.50&port=8080"

# 3. Query Kiểm tra Danh sách Service Đã Đăng Ký trên Nacos
kubectl run nacos-query-test --rm -i --tty --image=curlimages/curl:8.5.0 --namespace=datablue-test -- \
  curl -s "http://nacos-service.datablue-test.svc.cluster.local:8848/nacos/v1/ns/service/list?pageNo=1&pageSize=10"
```

### 5.3 Kiểm thử Cơ sở dữ liệu RDS MySQL (Database Verification)
```bash
# Lấy RDS Endpoint & Master Password từ Terraform Output
RDS_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_endpoint | cut -d: -f1)
RDS_PASSWORD=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_master_password)

# Tạo test table và truy vấn (dùng Pod tạm thời)
kubectl run mysql-test --rm -i --tty --image=mysql:8.0 --namespace=datablue-test -- bash -c "
mysql -h ${RDS_ENDPOINT} -u admin_databue -p'${RDS_PASSWORD}' -e '
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS health_check (id INT PRIMARY KEY AUTO_INCREMENT, checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO health_check VALUES ();
SELECT * FROM health_check;
'
"
```

### 5.4 Kiểm thử ElastiCache Redis (Cache Layer Test)
```bash
# Lấy Redis Endpoint & AUTH Token từ Terraform Output
REDIS_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw redis_primary_endpoint)
REDIS_AUTH=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw redis_auth_token)

# Chạy test PING, SET, GET với redis-cli có AUTH Token & TLS mã hóa từ Pod tạm
kubectl run redis-test --rm -i --tty --image=redis:7-alpine --namespace=datablue-test -- sh -c "
redis-cli -h ${REDIS_ENDPOINT} -a '${REDIS_AUTH}' --tls PING
redis-cli -h ${REDIS_ENDPOINT} -a '${REDIS_AUTH}' --tls SET test_key 'DataBlue_Test_Value' EX 300
redis-cli -h ${REDIS_ENDPOINT} -a '${REDIS_AUTH}' --tls GET test_key
"
```

### 5.5 Kiểm thử Amazon MQ RabbitMQ (Message Broker Test)
```bash
# Lấy RabbitMQ Endpoint từ Output
RABBITMQ_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rabbitmq_amqp_endpoints)

# Telemetry / Probe Port 5671 (AMQP TLS)
kubectl run rabbitmq-diag --rm -i --tty --image=busybox:1.36 --namespace=datablue-test -- sh -c "
nc -z -v -w 5 ${RABBITMQ_ENDPOINT#amqps://} 5671
"
```

### 5.6 Kiểm thử E2E Traffic qua Public NLB (End-to-End Test)
```bash
# Lấy Public NLB DNS Name từ Output
NLB_DNS=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw test_nlb_dns_name)

# Gửi HTTP GET Request qua Public NLB -> Fargate Proxy -> EKS Ingress
curl -i -v "http://${NLB_DNS}/health"

# Benchmark thử nghiệm tải nhỏ (Latency & Throughput Check)
for i in {1..10}; do
  curl -s -o /dev/null -w "Request %{http_code} - Time: %{time_total}s\n" "http://${NLB_DNS}/"
done
```

---

## 6. Monitoring & Day-2 Maintenance (CloudWatch, GuardDuty & K8s Ops)

### 6.1 Giám sát Bảo mật với AWS GuardDuty
```bash
# 1. Kiểm tra trạng thái GuardDuty Detector ở khu vực ap-southeast-1
aws guardduty list-detectors --region ap-southeast-1

# 2. Liệt kê các mối đe dọa / cảnh báo an ninh mới nhất (GuardDuty Findings)
DETECTOR_ID=$(aws guardduty list-detectors --region ap-southeast-1 --query "DetectorIds[0]" --output text)
aws guardduty list-findings --detector-id ${DETECTOR_ID} --region ap-southeast-1

# 3. Xem chi tiết các Cảnh báo An ninh
aws guardduty get-findings \
  --detector-id ${DETECTOR_ID} \
  --finding-ids $(aws guardduty list-findings --detector-id ${DETECTOR_ID} --query "FindingIds[:5]" --output text --region ap-southeast-1) \
  --region ap-southeast-1
```

### 6.2 Giám sát Nhật ký & Hiệu năng với CloudWatch & Container Insights
```bash
# 1. Kiểm tra các Log Groups của EKS Control Plane trên CloudWatch
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/eks/DataBlue-Test-EKS" \
  --region ap-southeast-1

# 2. Real-time Log Streaming cho EKS Audit Logs
aws logs tail /aws/eks/DataBlue-Test-EKS/cluster --follow --region ap-southeast-1

# 3. Kiểm tra các CloudWatch Alarms hiện có (Alarms CPU, RAM, Disk Utilization)
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --region ap-southeast-1
```

### 6.3 Scaling & Pod Management (Nacos & Microservices Ops)
```bash
# Scaling số lượng Pods của Nacos Server
kubectl scale deployment/nacos-server --replicas=2 -n datablue-test

# Thực hiện Restart không gián毒 Nacos (Rolling Restart)
kubectl rollout restart deployment/nacos-server -n datablue-test
kubectl rollout status deployment/nacos-server -n datablue-test

# Xem Log thời gian thực của Nacos Server
kubectl logs -f -l app=nacos-server -n datablue-test --tail=100
```

### 6.4 Node Management (Thao tác bảo trì Node Group)
```bash
# Khởi động lại / Drain Node khi cần bảo trì
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <node-name>
```

### 6.5 Backup & Snapshot Operations (Sao lưu & Phục hồi)
```bash
# Tạo Manual Snapshot cho RDS MySQL (Bao gồm dữ liệu Nacos và App)
aws rds create-db-snapshot \
  --db-instance-identifier datablue-test-mysql \
  --db-snapshot-identifier "manual-snap-$(date +%Y%m%d-%H%M%S)" \
  --region ap-southeast-1

# Kiểm tra danh sách Snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier datablue-test-mysql \
  --query "DBSnapshots[*].[DBSnapshotIdentifier,Status,SnapshotCreateTime]" \
  --region ap-southeast-1
```

### 6.6 Quy trình Tự động Tắt/Bật Môi trường Test Hàng đêm (Nightly Auto-Shutdown / Start for Cost Optimization)
> **Mục tiêu**: Giảm 50-60% chi phí chạy môi trường Test bằng cách tạm dừng tài nguyên ngoài giờ làm việc.

```bash
# ===== KỊCH BẢN TẮT HẠ TẦNG (NIGHTLY SHUTDOWN - 19:00 PM) =====
# 1. Scale EKS NodeGroup về 0 nodes
aws eks update-nodegroup-config \
  --cluster-name DataBlue-Test-EKS \
  --nodegroup-name datablue-test-eks-node-group \
  --scaling-config minSize=0,maxSize=4,desiredSize=0 \
  --region ap-southeast-1

# 2. Stop RDS MySQL Instance
aws rds stop-db-instance \
  --db-instance-identifier datablue-test-mysql \
  --region ap-southeast-1

# 3. Scale ECS Fargate Proxy Service về 0 tasks
aws ecs update-service \
  --cluster DataBlue-Test-Entry-ECS-Cluster \
  --service DataBlue-Test-Entry-Proxy-Service \
  --desired-count 0 \
  --region ap-southeast-1


# ===== KỊCH BẢN BẬT HẠ TẦNG (MORNING STARTUP - 07:00 AM) =====
# 1. Start RDS MySQL Instance
aws rds start-db-instance \
  --db-instance-identifier datablue-test-mysql \
  --region ap-southeast-1

# 2. Restore EKS NodeGroup về 2 nodes
aws eks update-nodegroup-config \
  --cluster-name DataBlue-Test-EKS \
  --nodegroup-name datablue-test-eks-node-group \
  --scaling-config minSize=2,maxSize=4,desiredSize=2 \
  --region ap-southeast-1

# 3. Scale ECS Fargate Proxy Service về 1 task
aws ecs update-service \
  --cluster DataBlue-Test-Entry-ECS-Cluster \
  --service DataBlue-Test-Entry-Proxy-Service \
  --desired-count 1 \
  --region ap-southeast-1
```

### 6.7 Quy trình Phục hồi Dữ liệu & Sự cố Disaster Recovery (DR & Restore Runbook)
> **Mục tiêu**: Phục hồi hệ thống khi có sự cố hỏng hóc database hoặc lỗi cấu hình nghiêm trọng (RTO < 1h, RPO < 24h).

```bash
# 1. Khôi phục RDS Database mới từ Snapshot gần nhất
SNAPSHOT_ID=$(aws rds describe-db-snapshots \
  --db-instance-identifier datablue-test-mysql \
  --query "DBSnapshots | sort_by(@, &SnapshotCreateTime)[-1].DBSnapshotIdentifier" \
  --output text --region ap-southeast-1)

echo "Restoring from latest snapshot: ${SNAPSHOT_ID}"

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "datablue-test-mysql-restored" \
  --db-snapshot-identifier "${SNAPSHOT_ID}" \
  --db-instance-class db.t4g.medium \
  --no-publicly-accessible \
  --region ap-southeast-1

# 2. Kiểm tra trạng thái Instance mới được restore
aws rds describe-db-instances \
  --db-instance-identifier datablue-test-mysql-restored \
  --query "DBInstances[0].[DBInstanceStatus, Endpoint.Address]" \
  --region ap-southeast-1

# 3. Cập nhật lại Endpoint trong Nacos Deployment
NEW_RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier datablue-test-mysql-restored \
  --query "DBInstances[0].Endpoint.Address" \
  --output text --region ap-southeast-1)

kubectl set env deployment/nacos-server -n datablue-test MYSQL_SERVICE_HOST=${NEW_RDS_ENDPOINT}
```

### 6.8 Quản lý Secrets, Lấy & Xoay vòng Mật khẩu MySQL (Secrets Management & Password Rotation)

#### 1. Cách Lấy Mật khẩu RDS MySQL Hiện Tại
Mật khẩu MySQL được tự động sinh ngẫu nhiên 24 ký tự ở lần `apply` đầu tiên và lưu cố định trong State File (không bị thay đổi ở các lần `apply` sau):
```bash
# Đọc mật khẩu MySQL Master hiện tại từ Terraform State Output
cd ${TERRAFORM_CODE_PATH}
MYSQL_PASS=$(terraform output -raw rds_mysql_master_password)
echo "Current RDS MySQL Password: ${MYSQL_PASS}"
```

#### 2. Cách Tạo / Sinh Mật khẩu Mới bằng Terraform (`taint`)
Khi bạn muốn bắt buộc Terraform hủy bỏ mật khẩu cũ và tự động sinh ra một mật khẩu ngẫu nhiên mới:
```bash
cd ${TERRAFORM_CODE_PATH}

# Đánh dấu resource random_password cần tái tạo lại
terraform taint module.rds_mysql.random_password.master_password

# Áp dụng thay đổi để sinh mật khẩu mới và cập nhật thẳng vào RDS
terraform apply -auto-approve

# Lấy lại mật khẩu mới vừa được sinh ra
NEW_MYSQL_PASS=$(terraform output -raw rds_mysql_master_password)
echo "New RDS MySQL Password: ${NEW_MYSQL_PASS}"
```

#### 3. Đọc & Xoay vòng Mật khẩu Trực tiếp trên AWS Secrets Manager
Terraform tự động tạo và lưu trữ tệp Secret JSON vào **AWS Secrets Manager** (`datablue/test/rds-mysql`) mã hóa bằng khóa KMS CMK. Bạn có thể đọc trực tiếp bằng AWS CLI:
```bash
# 1. Đọc nội dung JSON Secret từ AWS Secrets Manager
SECRET_NAME=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_secret_name)
aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --region ap-southeast-1 --query "SecretString" --output text

# 2. Xoay vòng mật khẩu (Rotate Password) trong Secrets Manager khi cần
ROTATE_PASS=$(openssl rand -base64 18)
aws secretsmanager update-secret \
  --secret-id ${SECRET_NAME} \
  --secret-string "{\"engine\":\"mysql\",\"host\":\"${RDS_ENDPOINT}\",\"port\":3306,\"username\":\"admin_databue\",\"password\":\"${ROTATE_PASS}\",\"dbname\":\"datablue_test_db\"}" \
  --region ap-southeast-1

# 3. Cập nhật mật khẩu RDS Master tương ứng ngay lập tức via AWS CLI
aws rds modify-db-instance \
  --db-instance-identifier datablue-test-mysql \
  --master-user-password "${ROTATE_PASS}" \
  --apply-immediately \
  --region ap-southeast-1
```

---

## 7. Environment Reset & Teardown

Khi hoàn tất giai đoạn kiểm thử, thực hiện hủy hạ tầng để tránh phát sinh chi phí ngoài ý muốn:

```bash
# 1. Xóa các dịch vụ Nacos, ArgoCD và Namespaces
helm uninstall argocd -n argocd --ignore-not-found
kubectl delete -f argocd-app.yaml --ignore-not-found
kubectl delete -f nacos-deployment.yaml --ignore-not-found
kubectl delete namespace datablue-test argocd --ignore-not-found

# 2. Xóa toàn bộ tài nguyên hạ tầng bằng Terraform
cd ${TERRAFORM_CODE_PATH}
terraform destroy -auto-approve
```
