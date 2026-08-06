# DataBlue Next-Gen Infrastructure Platform — Scenarios Operations Index

**Project Identifier**: `datablue-nextgen-infra-platform`  
**Governance Standard**: Architecture-First Governance Standard (`OPERATING-MODEL.md`)

---

## 📌 Operations Runbooks Index

| Runbook File | Deployment Scenario & Target Environment | Target Monthly Budget | Disaster Recovery & Operational SLAs |
| :--- | :--- | :--- | :--- |
| 🛠️ [**`REQUIRE-PREPARE.md`**](REQUIRE-PREPARE.md) | **Step 0: Prerequisites & Environment Preparation** | **Mandatory Step 0** | CLI Tooling, S3 State Buckets, DynamoDB Lock Tables, AWS Quotas & Service Roles. |
| 📖 [**`SCENARIO-1-OPERATIONS.md`**](SCENARIO-1-OPERATIONS.md) | **Scenario 1: Standard Non-Prod Test Baseline** | **$1,600 – $2,400 / mo** | 2-AZ Test Layout, Karpenter Spot Nodes, Non-Prod Reset Runbook. |
| 📖 [**`SCENARIO-2-OPERATIONS.md`**](SCENARIO-2-OPERATIONS.md) | **Scenario 2: Production Baseline** | **$4,200 – $6,100 / mo** | 3-AZ Production, GATE-07 CAB Approval, 30-Day PITR & Velero Restore. |
| 📖 [**`SCENARIO-3-OPERATIONS.md`**](SCENARIO-3-OPERATIONS.md) | **Scenario 3: Production High-Scale HA** | **$7,200 – $10,500 / mo** | Aurora 3 Replicas, Redis Sharded 6-Node, 10,000 User Load Test Runbook. |
| 📖 [**`SCENARIO-4-OPERATIONS.md`**](SCENARIO-4-OPERATIONS.md) | **Scenario 4: Production Cross-Region DR** | **$10,000 – $14,800 / mo** | Dual Region (Primary `us-east-1` + Standby `us-west-2`), **RTO < 4h \| RPO < 15m**. |
| 📖 [**`SCENARIO-5-OPERATIONS.md`**](SCENARIO-5-OPERATIONS.md) | **Scenario 5: Enterprise Multi-Account Isolation** | **$12,000 – $18,500 / mo** | 5-Account Landing Zone, Dev/Test 100% Isolation Audit, Emergency Isolation Protocol. |

---

## 🛠️ General Operations Standard Operating Procedures (SOP)

1. **Pre-requisites Check**: Always verify IAM session privileges and target account ID before running Terraform or `kubectl`.
2. **Acceptance Gates**: Deployments to Production require signed **CAB Authorization (`GATE-07`)**.
3. **Emergency Escalation**: On-call Cloud Platform SRE Lead handles PagerDuty alerts per `OPERATING-MODEL.md`.
