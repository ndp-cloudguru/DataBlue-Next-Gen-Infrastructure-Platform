# Scenario 2 Operational Runbook: Production Early-Start Environment

**Project Identifier**: `datablue-nextgen-infra-platform`  
**Target Environment**: Production Early-Start (`DataBlue-Prod-Account`)  
**Target Monthly Budget**: 💰 `$2,096.49 / month`  
**AWS Region**: Singapore (`ap-southeast-1`)  
**Governance Standard**: Architecture-First Governance Standard (`OPERATING-MODEL.md` & `TERRAFORM_PROD_EARLYSTART_PLANNING.md`)

---

## 1. Architecture Diagram & Infrastructure Topology

Scenario 2 implements a 3-Availability-Zone (`ap-southeast-1a`, `ap-southeast-1b`, `ap-southeast-1c`) Production Early-Start topology spanning **3 AWS Accounts** (Account 1: Main Core, Account 2: Prod Entry A, Account 3: Prod Entry B) interconnected via a centralized **AWS Transit Gateway Hub**:

```mermaid
graph TD
    classDef prodEntryFill fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#e65100;
    classDef prodCoreFill fill:#e0f2fe,stroke:#0284c7,stroke-width:2px,color:#0369a1;
    classDef tgwFill fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#4a148c;

    Users["👥 10,000 DAU / Mobile Apps"] -->|Public Traffic| CF["☁️ Cloudflare Edge CDN / WAF"]

    subgraph EntryLayer ["🌐 Production Public Entry Accounts"]
        subgraph Account2 ["🟡 Account 2: Prod Entry A"]
            NLB_A["Public NLB A"] --> FARGATE_A["ECS Fargate Proxy A<br/>(2 vCPU / 4GB Task)"]
        end

        subgraph Account3 ["🍊 Account 3: Prod Entry B"]
            NLB_B["Public NLB B"] --> FARGATE_B["ECS Fargate Proxy B<br/>(Redundant Standby)"]
        end
    end

    CF --> NLB_A
    CF --> NLB_B

    subgraph Account1 ["🔴 AWS Account 1: Main Core Account"]
        subgraph TGW_Layer ["🔀 Shared Transit Gateway"]
            TGW["AWS Transit Gateway<br/>(2 Attachments for Prod A & B)"]
        end

        subgraph ProdCoreVPC ["🔹 Production Core VPC (10.10.0.0/16)"]
            PROD_EKS["Amazon EKS Prod Cluster<br/>(DataBlue-Prod-EKS: 3x m7g.large Worker Nodes across 3 AZs)"]
            PROD_NACOS["Nacos Service Discovery<br/>(ClusterIP / NodePort)"]
            PROD_ECR["Amazon ECR Registry<br/>(IMMUTABLE Tags, KMS & Image Scanning)"]
            PROD_RDS[("RDS MySQL Prod Multi-AZ<br/>datablue-prod-mysql db.t4g.xlarge 200GB GP3")]
            PROD_REDIS[("ElastiCache Redis Prod 2-Node<br/>datablue-prod-redis cache.t4g.large Primary/Replica")]
            PROD_MQ["Amazon MQ RabbitMQ Prod<br/>datablue-prod-rabbitmq mq.m5.small Active/Standby"]

            PROD_EKS --> PROD_NACOS
            PROD_EKS --> PROD_ECR
            PROD_EKS --> PROD_RDS
            PROD_EKS --> PROD_REDIS
            PROD_EKS --> PROD_MQ
            PROD_NACOS --> PROD_RDS
        end
    end

    FARGATE_A -->|Attachment 1| TGW
    FARGATE_B -->|Attachment 2| TGW
    TGW --> PROD_EKS

    class Account2,Account3 prodEntryFill;
    class Account1 prodCoreFill;
    class TGW_Layer tgwFill;
```

### Resource Specification Matrix

| Hạng mục Dịch vụ | Thành phần Hạ tầng | Cấu hình Chi tiết / Identifier | Số lượng | vCPU / RAM | Chi phí Hàng tháng | Ghi chú Tối ưu & Thiết lập Kỹ thuật |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **Networking** | **Prod Core VPC** | `10.10.0.0/16` (Account 1) | 1 VPC | - | $114.94 | 3-AZ (`ap-southeast-1a/b/c`), NAT Gateways, Subnets |
| **Networking** | **Prod Entry VPC A** | `10.20.0.0/16` (Account 2) | 1 VPC | - | $80.00 | Public NLB A + ECS Fargate Proxy A Task (2 vCPU / 4GB) |
| **Networking** | **Prod Entry VPC B** | `10.30.0.0/16` (Account 3) | 1 VPC | - | $80.00 | Public NLB B + ECS Fargate Proxy B Standby |
| **Networking** | **Transit Gateway** | AWS TGW (Account 1 Shared) | 2 Attachments | - | $173.00 | Nối Prod Entry A & B sang Production Core VPC |
| **Security** | **AWS KMS Key** | Customer Managed Key (CMK) | 1 Key | - | $3.00 | Mã hóa tĩnh At-Rest cho RDS, EKS, Redis, MQ & S3 |
| **Registry** | **Amazon ECR** | `datablue-prod/*` Repositories | 3 Repos | - | Free Tier / Pay-per-GB | Scan on push, KMS Encrypted, IMMUTABLE Tags |
| **Compute** | **Amazon EKS Cluster** | `DataBlue-Prod-EKS` | 1 Cluster | AWS Managed | $73.00 | Kubernetes v1.30 Control Plane Standard Support |
| **Compute** | **EKS Worker Node Group** | `m7g.large` (Graviton3 ARM64) | 3 Nodes | 6 vCPU / 24 GiB | $379.50 | 3 Nodes trải dài 3 AZs (đáp ứng 3k WebSockets) |
| **Registry / Config**| **Nacos Service** | `nacos-server` | 1 Pod | Shared EKS | $0.00 | Registered on EKS with MySQL RDS Backend |
| **Database** | **Amazon RDS MySQL** | `datablue-prod-mysql` | Multi-AZ | 4 vCPU / 16 GiB | $360.00 | `db.t4g.xlarge` Multi-AZ + 200GB đĩa GP3 ($29.00) |
| **Cache** | **ElastiCache Redis** | `datablue-prod-redis` | 2 Nodes | 4 vCPU / 12.7 GiB | $240.00 | `cache.t4g.large` Primary/Replica (TTL 1 giờ) |
| **Messaging** | **Amazon MQ RabbitMQ** | `datablue-prod-rabbitmq` | 2 Brokers | 4 vCPU / 4 GiB | $190.00 | `mq.m5.small` Active/Standby Event Buffer |
| **Storage & Logs** | **S3 & CloudWatch** | S3 Auto-Delete + CloudWatch | Shared | - | $479.30 | S3 1-Hour Media Auto-Delete + 50GB Logs |
| **TỔNG CỘNG** | **PROD EARLY-START** | **Production Core & 2 Entry Accounts** | **15 Tài nguyên** | **18 vCPU / 56 GiB** | 💰 **$2,096.49/tháng** | **Cấu hình tối ưu chi phí cho môi trường Production Early-Start** |

### 1.2 Cấu trúc Mã nguồn Hạ tầng Terraform (Terraform Codebase Structure)

```text
scenarios/
├── modules/                                # 📦 THƯ MỤC MODULES TÁI SỬ DỤNG (REUSABLE MODULES)
│   ├── amazon_mq_rabbitmq/                 # Module Amazon MQ RabbitMQ Broker
│   ├── ecr/                                # Module Amazon ECR Container Registry (KMS & Scanning)
│   ├── eks/                                # Module Amazon EKS Cluster & Worker NodeGroup
│   ├── elasticache_redis/                  # Module ElastiCache Redis Replication Group
│   ├── kms/                                # Module AWS KMS Customer Managed Key (CMK)
│   ├── rds_mysql/                          # Module RDS MySQL Instance
│   └── vpc/                                # Module VPC Networking (Subnets, NAT, Route Tables)
│
└── scenario-2-prod-baseline/               # 🚀 ROOT MODULE PRODUCTION EARLY-START (ap-southeast-1)
    ├── main.tf                             # Orchestration chính, TGW Hub & Multi-Account Providers
    ├── variables.tf                        # Khai báo biến đầu vào (3 VPC CIDRs, 3 AWS Profiles)
    ├── outputs.tf                          # Xuất Endpoints, ARNs, 2 NLB DNS & Subnet Layers
    └── terraform.tfvars                    # Giá trị biến thực tế Production
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

Hạ tầng Scenario 2 triển khai trên **3 AWS Accounts riêng biệt** (Account 1: Prod Core, Account 2: Prod Entry A, Account 3: Prod Entry B). Bạn cần cấu hình 3 AWS Profiles tương ứng:

#### Cách 1: Sử dụng AWS Access Key / Secret Key (`~/.aws/credentials`)
```ini
[datablue-prod-core]
aws_access_key_id = AKIA1111111111111111
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
region = ap-southeast-1

[datablue-prod-entry-a]
aws_access_key_id = AKIA2222222222222222
aws_secret_access_key = yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
region = ap-southeast-1

[datablue-prod-entry-b]
aws_access_key_id = AKIA3333333333333333
aws_secret_access_key = zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz
region = ap-southeast-1
```

#### Cách 2: Sử dụng AWS SSO (Single Sign-On - `~/.aws/config`)
```ini
[profile datablue-prod-core]
sso_start_url = https://datablue.awsapps.com/start
sso_region = ap-southeast-1
sso_account_id = 111111111111
sso_role_name = AWSAdministratorAccess
region = ap-southeast-1

[profile datablue-prod-entry-a]
sso_start_url = https://datablue.awsapps.com/start
sso_region = ap-southeast-1
sso_account_id = 222222222222
sso_role_name = AWSAdministratorAccess
region = ap-southeast-1

[profile datablue-prod-entry-b]
sso_start_url = https://datablue.awsapps.com/start
sso_region = ap-southeast-1
sso_account_id = 333333333333
sso_role_name = AWSAdministratorAccess
region = ap-southeast-1
```

#### 📌 Đăng nhập & Xác nhận Identities trước khi chạy Terraform
```bash
# 1. Đăng nhập SSO (nếu sử dụng SSO)
aws sso login --profile datablue-prod-core
aws sso login --profile datablue-prod-entry-a
aws sso login --profile datablue-prod-entry-b

# 2. Thiết lập các biến môi trường cấu hình chính
export AWS_REGION="ap-southeast-1"
export TERRAFORM_CODE_PATH="scenarios/scenario-2-prod-baseline"

# 3. Kiểm tra và đối soát Identity của cả 3 Accounts
aws sts get-caller-identity --profile datablue-prod-core
aws sts get-caller-identity --profile datablue-prod-entry-a
aws sts get-caller-identity --profile datablue-prod-entry-b

# 4. Lấy Account ID của Account Core để sử dụng cho ECR / EKS
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile datablue-prod-core --query "Account" --output text)
```

### 2.3 Kiểm tra AWS Service Quotas & Đối chiếu Yêu cầu Hạ tầng (Pre-Apply Quotas Audit)

Trước khi thực thi `terraform apply`, bắt buộc kiểm tra các Service Quotas trên tài khoản AWS để đảm bảo hạ tầng không bị gián đoạn do vượt ngưỡng giới hạn tài nguyên.

#### Option 1: Chạy Script Tự động Kiểm tra & Báo cáo Quotas (Khuyên dùng)
```bash
./scenarios/operations/scripts/check_aws_quotas.sh --scenario 2 --profile datablue-prod-core --region ap-southeast-1
```

#### Option 2: Kiểm tra từng Quota thủ công bằng AWS CLI
```bash
# 1. Kiểm tra Quota vCPU On-Demand Standard (Yêu cầu >= 6 vCPUs cho 3x m7g.large EKS Worker Nodes)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region ap-southeast-1 \
  --profile datablue-prod-core \
  --query "Quota.[QuotaName, Value]"

# 2. Kiểm tra Quota Elastic IP (Yêu cầu 3 EIPs cho 3-AZ NAT Gateways tại Account 1 Core)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --region ap-southeast-1 \
  --profile datablue-prod-core \
  --query "Quota.[QuotaName, Value]"

# 3. Kiểm tra Quota VPCs per Region (Yêu cầu 1 VPC trên mỗi Account 1, 2, 3)
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-F678F1CE \
  --region ap-southeast-1 \
  --profile datablue-prod-core \
  --query "Quota.[QuotaName, Value]"

# 4. Kiểm tra Quota NAT Gateways per AZ (Yêu cầu 3 NAT Gateways cho 3-AZ Prod Core)
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-FE5A405D \
  --region ap-southeast-1 \
  --profile datablue-prod-core \
  --query "Quota.[QuotaName, Value]"
```

#### 📊 Bảng Đối chiếu Quota Hạn Ngạch & Nhu cầu Hạ tầng Scenario 2

| Dịch vụ AWS | Mã Quota Code | Yêu cầu Scenario 2 (Required) | Hạn ngạch Mặc định | Đánh giá Khả thi |
| :--- | :--- | :---: | :---: | :---: |
| **EC2 On-Demand Standard vCPUs** | `L-1216C47A` | **6 vCPUs** (3x m7g.large) | 8.0 – 32.0 vCPUs | ✅ Đạt |
| **Elastic IP (EIP)** | `L-0263D0A3` | **3 EIPs** (3 NAT Gateways) | 5 EIPs | ✅ Đạt |
| **VPCs per Region** | `L-F678F1CE` | **1 VPC** / Account | 5 VPCs | ✅ Đạt |
| **NAT Gateways per AZ** | `L-FE5A405D` | **1 NAT GW** / AZ (Tổng 3) | 5 NAT GWs / AZ | ✅ Đạt |

---

## 3. Infrastructure Provisioning & Real-Time Monitoring

### 3.1 Khởi tạo và Triển khai Hạ tầng bằng Terraform
```bash
# 1. Chuyển vào thư mục chứa mã nguồn Terraform Scenario 2
cd ${TERRAFORM_CODE_PATH}

# 2. Khởi tạo S3 Bucket & DynamoDB Lock Table (Thực hiện nếu chưa có sẵn Backend S3)
aws s3api create-bucket \
  --bucket datablue-tfstate-ap-southeast-1 \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1 \
  --profile datablue-prod-core

aws s3api put-bucket-versioning \
  --bucket datablue-tfstate-ap-southeast-1 \
  --versioning-configuration Status=Enabled \
  --profile datablue-prod-core

aws s3api put-bucket-encryption \
  --bucket datablue-tfstate-ap-southeast-1 \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile datablue-prod-core

aws s3api put-public-access-block \
  --bucket datablue-tfstate-ap-southeast-1 \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile datablue-prod-core

aws dynamodb create-table \
  --table-name datablue-prod-tflocks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1 \
  --profile datablue-prod-core

# 3. Khởi tạo Terraform & Backend (S3 + DynamoDB Lock)
terraform init \
  -backend-config="bucket=datablue-tfstate-ap-southeast-1" \
  -backend-config="key=env/prod/terraform.tfstate" \
  -backend-config="region=ap-southeast-1" \
  -backend-config="dynamodb_table=datablue-prod-tflocks"

# 3. Kiểm tra cú pháp và tính hợp lệ của HCL
terraform validate

# 4. Tự động định dạng lại code
terraform fmt

# 5. Xem trước kế hoạch thay đổi hạ tầng
terraform plan -out=tfplan-prod

# 6. Triển khai hạ tầng (sau khi nhận phê duyệt từ CAB)
terraform apply tfplan-prod
```

### 3.2 Lệnh Giám sát & Check Trạng thái trong khi Triển khai (Terraform & AWS Monitoring)
```bash
# A. Kiểm tra State và Lock Status trên S3 / DynamoDB
aws s3 ls s3://datablue-tfstate-ap-southeast-1/env/prod/
aws dynamodb get-item \
  --table-name datablue-prod-tflocks \
  --key '{"LockID": {"S": "datablue-tfstate-ap-southeast-1/env/prod/terraform.tfstate-md5"}}'

# B. Theo dõi trạng thái AWS Transit Gateway & Attachments
aws ec2 describe-transit-gateways --region ap-southeast-1
aws ec2 describe-transit-gateway-vpc-attachments --region ap-southeast-1

# C. Theo dõi tiến độ tạo EKS Prod Cluster (3 Nodes Multi-AZ)
watch -n 5 "aws eks describe-cluster --name DataBlue-Prod-EKS --region ap-southeast-1 --query 'cluster.status'"

# D. Theo dõi trạng thái khởi tạo RDS MySQL Multi-AZ Instance
watch -n 5 "aws rds describe-db-instances --db-instance-identifier datablue-prod-mysql --region ap-southeast-1 --query 'DBInstances[0].[DBInstanceStatus, Endpoint.Address]'"

# E. Kiểm tra trạng thái ElastiCache Redis Replication Group
aws elasticache describe-replication-groups \
  --replication-group-id datablue-prod-redis \
  --region ap-southeast-1 \
  --query "ReplicationGroups[0].[Status, NodeGroups[0].PrimaryEndpoint.Address]"

# F. Xem tất cả Outputs đã tạo
terraform output
```

### 3.3 Kết quả Terraform Outputs & Đối soát Sơ đồ Kiến trúc (Expected Outputs & Architecture Mapping)

Sau khi thực hiện `terraform apply` thành công, màn hình sẽ trả về bộ **Outputs chuẩn Production**:

```hcl
Outputs:

ecr_repository_urls = {
  "datablue-prod/backend-api" = "111111111111.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-prod/backend-api"
  "datablue-prod/envoy-proxy" = "111111111111.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-prod/envoy-proxy"
  "datablue-prod/frontend"    = "111111111111.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-prod/frontend"
}
eks_cluster_endpoint                 = "https://PROD123456789.gr7.ap-southeast-1.eks.amazonaws.com"
eks_cluster_name                     = "DataBlue-Prod-EKS"
kms_key_arn                          = "arn:aws:kms:ap-southeast-1:111111111111:key/prod-1234-1234-1234-123456789012"
prod_core_vpc_id                     = "vpc-0core111111111111"
prod_entry_a_nlb_dns_name            = "DataBlue-Prod-EntryA-NLB-12345.elb.ap-southeast-1.amazonaws.com"
prod_entry_a_vpc_id                  = "vpc-0entrya2222222222"
prod_entry_b_nlb_dns_name            = "DataBlue-Prod-EntryB-NLB-67890.elb.ap-southeast-1.amazonaws.com"
prod_entry_b_vpc_id                  = "vpc-0entryb3333333333"
rabbitmq_amqp_endpoints              = [
  "amqps://b-11111111-1.mq.ap-southeast-1.amazonaws.com:5671"
]
rds_mysql_endpoint                   = "datablue-prod-mysql.c123456789.ap-southeast-1.rds.amazonaws.com:3306"
rds_mysql_secret_name            = "datablue/production/rds-mysql"
rds_mysql_secret_arn             = "arn:aws:secretsmanager:ap-southeast-1:111111111111:secret:datablue/production/rds-mysql-654321"
redis_primary_endpoint               = "datablue-prod-redis.123456.ng.001.apse1.cache.amazonaws.com"

# AWS Transit Gateway Hub & Attachments Outputs
transit_gateway_arn                  = "arn:aws:ec2:ap-southeast-1:111111111111:transit-gateway/tgw-0123456789abcdef0"
transit_gateway_attachment_core_id   = "tgw-attach-0core111111111111"
transit_gateway_attachment_entry_a_id = "tgw-attach-0entrya22222222"
transit_gateway_attachment_entry_b_id = "tgw-attach-0entryb33333333"
transit_gateway_id                   = "tgw-0123456789abcdef0"

# Network Subnet Layer Outputs (3-AZ)
prod_core_public_subnet_ids          = [
  "subnet-0puba11111111", # 10.10.1.0/24 (ap-southeast-1a)
  "subnet-0pubb22222222", # 10.10.2.0/24 (ap-southeast-1b)
  "subnet-0pubc33333333"  # 10.10.3.0/24 (ap-southeast-1c)
]
prod_core_private_app_subnet_ids     = [
  "subnet-0appa11111111", # 10.10.10.0/24 (ap-southeast-1a)
  "subnet-0appb22222222", # 10.10.20.0/24 (ap-southeast-1b)
  "subnet-0appc33333333"  # 10.10.30.0/24 (ap-southeast-1c)
]
prod_core_database_subnet_ids        = [
  "subnet-0dba111111111", # 10.10.100.0/24 (ap-southeast-1a)
  "subnet-0dbb222222222", # 10.10.200.0/24 (ap-southeast-1b)
  "subnet-0dbc333333333"  # 10.10.300.0/24 (ap-southeast-1c)
]
```

#### 📊 Bảng Đối soát Output với Sơ đồ Kiến trúc & Hạng mục Vận hành

| Tên Output Terraform | Ý nghĩa & Vị trí trên Sơ đồ Kiến trúc | Dùng cho Bước Vận hành Nào? |
| :--- | :--- | :--- |
| **`prod_core_vpc_id`** | Account 1 Prod Core VPC (`10.10.0.0/16`) | Kiểm tra mạng nội bộ 3-AZ (`Section 3.2`) |
| **`prod_entry_a_vpc_id`** | Account 2 Prod Entry A VPC (`10.20.0.0/16`) | Kiểm tra Fargate Proxy A Security Groups |
| **`prod_entry_b_vpc_id`** | Account 3 Prod Entry B VPC (`10.30.0.0/16`) | Kiểm tra Fargate Proxy B Security Groups |
| **`transit_gateway_id` & `arn`** | AWS Transit Gateway Hub (Account 1 Shared Hub) | Central Router nối 3 Accounts (`Section 5.1`) |
| **`transit_gateway_attachment_*_id`**| TGW VPC Attachments kết nối Core, Entry A & Entry B | Cross-Account VPC Connectivity Check (`Section 5.1`) |
| **`prod_core_public_subnet_ids`** | Lớp Public Subnets Core 3-AZ (`10.10.1.0..3.0/24`) | Nơi đặt 3 Public NAT Gateways ra Internet |
| **`prod_core_private_app_subnet_ids`**| Lớp Private App Subnets Core (`10.10.10.0..30.0/24`) | Nơi đặt 3 Worker Nodes EKS, Nacos & ArgoCD |
| **`prod_core_database_subnet_ids`** | Lớp Isolated DB Subnets Core (`10.10.100.0..300.0/24`)| Nơi đặt RDS MySQL Multi-AZ, Redis & RabbitMQ |
| **`eks_cluster_name` & `endpoint`** | Cluster Name & Control Plane EKS (3x m7g.large) | Cấu hình `aws eks update-kubeconfig` (`Section 4.1`) |
| **`ecr_repository_urls`** | Repositories Amazon ECR (Tags IMMUTABLE) | Docker Login, Build & Push Images (`Section 4.3`) |
| **`rds_mysql_endpoint`** | Endpoint csdl RDS MySQL Multi-AZ (`db.t4g.xlarge`) | Cấu hình Nacos (`Section 4.4`) & MySQL Test (`Section 5.3`) |
| **`redis_primary_endpoint`** | Endpoint ElastiCache Redis Cluster (`cache.t4g.large`) | Redis PING & Cache Verification (`Section 5.4`) |
| **`rabbitmq_amqp_endpoints`** | Endpoint AMQP (Port 5671) Amazon MQ (`mq.m5.small`) | RabbitMQ Connectivity Diagnostic (`Section 5.5`) |
| **`prod_entry_a_nlb_dns_name`** | DNS Public NLB A (Account 2) | Cấu hình Cloudflare Edge WAF & E2E Test (`Section 5.6`) |
| **`prod_entry_b_nlb_dns_name`** | DNS Public NLB B (Account 3 - Standby) | Failover testing qua Cloudflare Edge (`Section 5.6`) |

---

## 4. Service Deployment, ECR & ArgoCD GitOps Runbook

### 4.1 Kết nối và Cấu hình Kubernetes EKS Production
```bash
# Cập nhật kubeconfig local kết nối tới EKS Prod Cluster
aws eks update-kubeconfig --region ap-southeast-1 --name DataBlue-Prod-EKS

# Kiểm tra phân bổ 3 Nodes trên 3 Availability Zones (Multi-AZ Topology)
kubectl get nodes -L topology.kubernetes.io/zone -o wide
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

# 4. Lấy mật khẩu admin ban đầu của ArgoCD
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: ${ARGOCD_PASSWORD}"
```

### 4.3 Quản lý Amazon ECR & Build/Push Docker Images (IMMUTABLE Tags)

**Bước 1:** Đăng nhập vào ECR Registry
```bash
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com
```

**Bước 2:** Build, Tag và Push Image ứng dụng lên Production ECR
```bash
REGISTRY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com"
IMAGE_TAG="v1.0.0-release"

# Build & Push Backend API Image
docker build -t datablue-prod/backend-api:${IMAGE_TAG} ./backend
docker tag datablue-prod/backend-api:${IMAGE_TAG} ${REGISTRY_URL}/datablue-prod/backend-api:${IMAGE_TAG}
docker push ${REGISTRY_URL}/datablue-prod/backend-api:${IMAGE_TAG}
```

**Bước 3:** Kiểm tra kết quả quét lỗ hổng bảo mật (Image Scan Findings)
```bash
aws ecr describe-image-scan-findings \
  --repository-name datablue-prod/backend-api \
  --image-id imageTag=${IMAGE_TAG} \
  --region ap-southeast-1
```

### 4.4 Triển khai Nacos Service (Service Discovery & Naming Server)

**Bước 1:** Tạo Namespace `datablue-prod`
```bash
kubectl create namespace datablue-prod --dry-run=client -o yaml | kubectl apply -f -
```

**Bước 2:** Lấy thông tin RDS Endpoint & Master Password từ Terraform Output
```bash
RDS_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_endpoint | cut -d: -f1)
RDS_PASSWORD=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_master_password)
echo "RDS Endpoint: ${RDS_ENDPOINT}"
```

**Bước 3:** Tạo file manifest `nacos-deployment.yaml`

Lưu đoạn cấu hình sau vào file `nacos-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nacos-server
  namespace: datablue-prod
  labels:
    app.kubernetes.io/name: nacos-server
    app.kubernetes.io/part-of: datablue-platform
spec:
  replicas: 2
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
          value: "datablue_prod_db"
        - name: MYSQL_SERVICE_USER
          value: "admin_databue_prod"
        - name: MYSQL_SERVICE_PASSWORD
          value: "YOUR_RDS_PASSWORD"
        ports:
        - containerPort: 8848
          name: client-port
        - containerPort: 9848
          name: client-grpc
        resources:
          requests:
            memory: "1024Mi"
            cpu: "500m"
          limits:
            memory: "2048Mi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: nacos-service
  namespace: datablue-prod
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

# Kiểm tra trạng thái Deployment và Pods trên 3 AZs
kubectl get pods -l app=nacos-server -n datablue-prod -o wide
```

### 4.5 Triển khai App thử nghiệm bằng ArgoCD Application Manifest

**Bước 1:** Tạo file manifest `argocd-app-prod.yaml`

Lưu cấu hình dưới đây vào file `argocd-app-prod.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: datablue-prod-services
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/datablue/k8s-manifests.git'
    targetRevision: HEAD
    path: environments/production
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: datablue-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

**Bước 2:** Thực thi áp dụng Manifest

```bash
kubectl apply -f argocd-app-prod.yaml

# Kiểm tra trạng thái ứng dụng trên ArgoCD
kubectl get application -n argocd
```

---

## 5. Comprehensive Testing & Verification Suite (Các kịch bản Kiểm thử)

### 5.1 Kiểm thử Kết nối Mạng Transit Gateway (Cross-VPC TGW Diagnostic)
```bash
# 1. Kiểm tra trạng thái TGW Route Tables & Attachments
TGW_ID=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw transit_gateway_id)
aws ec2 describe-transit-gateway-vpc-attachments --filters "Name=transit-gateway-id,Values=${TGW_ID}" --region ap-southeast-1

# 2. Kiểm tra phân giải DNS và mạng nội bộ xuyên VPC từ Pod
kubectl run network-diag-prod --rm -i --tty --image=busybox:1.36 --namespace=datablue-prod -- restart=Never -- nslookup kubernetes.default
```

### 5.2 Kiểm thử Nacos Service Discovery API
```bash
kubectl run nacos-health-prod --rm -i --tty --image=curlimages/curl:8.5.0 --namespace=datablue-prod -- \
  curl -s "http://nacos-service.datablue-prod.svc.cluster.local:8848/nacos/actuator/health"
```

### 5.3 Kiểm thử Cơ sở dữ liệu RDS MySQL Multi-AZ
```bash
RDS_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_endpoint | cut -d: -f1)
RDS_PASSWORD=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_master_password)

kubectl run mysql-test-prod --rm -i --tty --image=mysql:8.0 --namespace=datablue-prod -- bash -c "
mysql -h ${RDS_ENDPOINT} -u admin_databue_prod -p'${RDS_PASSWORD}' -e '
CREATE DATABASE IF NOT EXISTS prod_check_db;
USE prod_check_db;
CREATE TABLE IF NOT EXISTS health_check (id INT PRIMARY KEY AUTO_INCREMENT, checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO health_check VALUES ();
SELECT * FROM health_check;
'
"
```

### 5.4 Kiểm thử ElastiCache Redis Cluster (AUTH Token + TLS)
```bash
REDIS_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw redis_primary_endpoint)
REDIS_AUTH=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw redis_auth_token)

kubectl run redis-test-prod --rm -i --tty --image=redis:7-alpine --namespace=datablue-prod -- sh -c "
redis-cli -h ${REDIS_ENDPOINT} -a '${REDIS_AUTH}' --tls PING
redis-cli -h ${REDIS_ENDPOINT} -a '${REDIS_AUTH}' --tls SET prod_test_key 'DataBlue_Prod_Value' EX 300
redis-cli -h ${REDIS_ENDPOINT} -a '${REDIS_AUTH}' --tls GET prod_test_key
"
```

### 5.5 Kiểm thử Amazon MQ RabbitMQ Active/Standby Broker
```bash
RABBITMQ_ENDPOINT=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rabbitmq_amqp_endpoints)

kubectl run rabbitmq-diag-prod --rm -i --tty --image=busybox:1.36 --namespace=datablue-prod -- sh -c "
nc -z -v -w 5 ${RABBITMQ_ENDPOINT#amqps://} 5671
"
```

### 5.6 Kiểm thử E2E Traffic qua Cloudflare Edge & Dual NLBs (Account 2 & Account 3)
```bash
NLB_A_DNS=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw prod_entry_a_nlb_dns_name)
NLB_B_DNS=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw prod_entry_b_nlb_dns_name)

# Kiểm tra kết nối tới NLB A (Entry A Account 2)
curl -i -v "http://${NLB_A_DNS}/health"

# Kiểm tra kết nối tới NLB B (Entry B Account 3)
curl -i -v "http://${NLB_B_DNS}/health"
```

---

## 6. Monitoring, Disaster Recovery & Security Maintenance

### 6.1 Giám sát Bảo mật với AWS GuardDuty
```bash
aws guardduty list-detectors --region ap-southeast-1
```

### 6.2 CloudWatch & Container Insights Streaming
```bash
aws logs tail /aws/eks/DataBlue-Prod-EKS/cluster --follow --region ap-southeast-1
```

### 6.3 Backup & Snapshot Operations (RDS 30-Day PITR)
```bash
# Tạo Manual Snapshot cho RDS MySQL Multi-AZ
aws rds create-db-snapshot \
  --db-instance-identifier datablue-prod-mysql \
  --db-snapshot-identifier "prod-manual-snap-$(date +%Y%m%d-%H%M%S)" \
  --region ap-southeast-1
```

### 6.4 Quy trình Phục hồi Dữ liệu & Sự cố Disaster Recovery (DR Runbook)
```bash
# 1. Khôi phục RDS Database mới từ Snapshot gần nhất
SNAPSHOT_ID=$(aws rds describe-db-snapshots \
  --db-instance-identifier datablue-prod-mysql \
  --query "DBSnapshots | sort_by(@, &SnapshotCreateTime)[-1].DBSnapshotIdentifier" \
  --output text --region ap-southeast-1)

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "datablue-prod-mysql-restored" \
  --db-snapshot-identifier "${SNAPSHOT_ID}" \
  --db-instance-class db.t4g.xlarge \
  --multi-az \
  --no-publicly-accessible \
  --region ap-southeast-1
```

### 6.5 Quản lý Secrets, Lấy & Xoay vòng Mật khẩu MySQL (Secrets Management & Rotation)

```bash
# 1. Đọc mật khẩu MySQL Master hiện tại từ Terraform State Output
cd ${TERRAFORM_CODE_PATH}
MYSQL_PASS=$(terraform output -raw rds_mysql_master_password)
echo "Current Prod RDS Password: ${MYSQL_PASS}"

# 2. Đọc tệp JSON Credentials trực tiếp từ AWS Secrets Manager bằng AWS CLI
SECRET_NAME=$(cd ${TERRAFORM_CODE_PATH} && terraform output -raw rds_mysql_secret_name)
aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --region ap-southeast-1 --query "SecretString" --output text

# 3. Tự động sinh lại mật khẩu ngẫu nhiên mới bằng terraform taint khi cần
terraform taint module.rds_mysql.random_password.master_password
terraform apply -auto-approve

# 4. Xoay vòng mật khẩu (Rotate Password) trong Secrets Manager & RDS CLI
ROTATE_PASS=$(openssl rand -base64 18)
aws secretsmanager update-secret \
  --secret-id ${SECRET_NAME} \
  --secret-string "{\"engine\":\"mysql\",\"host\":\"${RDS_ENDPOINT}\",\"port\":3306,\"username\":\"admin_databue_prod\",\"password\":\"${ROTATE_PASS}\",\"dbname\":\"datablue_prod_db\"}" \
  --region ap-southeast-1

aws rds modify-db-instance \
  --db-instance-identifier datablue-prod-mysql \
  --master-user-password "${ROTATE_PASS}" \
  --apply-immediately \
  --region ap-southeast-1
```

---

## 7. Environment Teardown (Nếu cần thiết)

```bash
# 1. Xóa các ứng dụng K8s
kubectl delete -f argocd-app-prod.yaml --ignore-not-found
kubectl delete -f nacos-deployment.yaml --ignore-not-found

# 2. Xóa toàn bộ hạ tầng bằng Terraform
cd ${TERRAFORM_CODE_PATH}
terraform destroy -auto-approve
```
