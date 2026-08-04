# Middleware Delivery Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies individual delivery paths, high-availability topologies, backup methods, and operational lifecycles for the five stateful middleware services required by the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`):
1. **MySQL** (`FUN-005`)
2. **Redis** (`FUN-008`)
3. **RabbitMQ** (`FUN-006`)
4. **MongoDB** (`FUN-007`)
5. **Nacos** (`FUN-009`)

Unresolved Stage 3 ADRs (`ADR-006`..`009`) are highlighted with their required unblocking evidence.

---

## 2. Middleware Component Delivery Specifications

### 2.1 MySQL Relational Database (`FUN-005`)
* **Proposed / Candidate Deployment Model**: Amazon RDS for MySQL (Multi-AZ) vs. Self-Hosted MySQL Operator on EKS (`ADR Candidate: ADR-006`).
* **Unresolved ADR Status**: **`Deferred`** (`ADR-006`).
* **Unblocking Required Evidence**: DB storage size, transaction IOPS, and read/write ratio from Phase 0 (`OPEN-001`).
* **Environment Topology**: Primary instance in AZ-a, synchronous standby instance in AZ-b (Database VPC Subnets).
* **High Availability Model**: Automated Multi-AZ failover (< 60 seconds) with DNS CNAME switchover (`NFR-001`).
* **Backup & Restore Method**: Daily automated snapshots + 30-day Point-in-Time Recovery (PITR) continuous transaction logging (`ADR-013`). Automated monthly restore verification to isolated Test subnets (`RSK-DAT-002`).
* **Monitoring & Alerts**: AWS CloudWatch + Prometheus mysqld_exporter metrics (Connection count > 80%, CPU > 85%, Storage Free < 15%).
* **Scaling Method**: Vertical instance resizing (`db.m6g.xlarge`) + Read-Replica endpoint offloading (`NFR-004`).
* **Upgrade Method**: AWS managed engine minor version upgrades during maintenance windows.
* **Failure Recovery**: Automated secondary instance promotion upon primary host or AZ failure.
* **Data Migration Requirements**: Initial schema and seed data import via `mysqldump` / AWS Database Migration Service (DMS).

---

### 2.2 Redis In-Memory Cache (`FUN-008`)
* **Proposed / Candidate Deployment Model**: Amazon ElastiCache for Redis vs. Self-Hosted Redis Cluster on EKS (`ADR Candidate: ADR-007`).
* **Unresolved ADR Status**: **`Deferred`** (`ADR-007`).
* **Unblocking Required Evidence**: Cache memory RAM footprint and eviction policy profiling (`OPEN-001`).
* **Environment Topology**: 2-node / 3-node Replication Group spanning AZ-a, AZ-b, and AZ-c (Database Subnets).
* **High Availability Model**: Multi-AZ primary/replica failover (< 30 seconds) with automatic endpoint routing.
* **Backup Method**: Daily automated RDB snapshot export to S3 (`ADR-013`).
* **Monitoring & Alerts**: ElastiCache `EngineCPUUtilization`, `DatabaseMemoryUsagePercentage`, and `CacheMissRate` metric alerts.
* **Scaling Method**: Online instance node resizing (`cache.m6g.large`) and cluster shard expansion.
* **Upgrade Method**: Managed maintenance window version updates.
* **Failure Recovery**: Automatic primary node failover to secondary replica.
* **Data Migration Requirements**: Transient cache warming via application logic.

---

### 2.3 RabbitMQ Message Broker (`FUN-006`)
* **Proposed / Candidate Deployment Model**: RabbitMQ Cluster Kubernetes Operator on EKS vs. Amazon MQ for RabbitMQ (`ADR Candidate: ADR-008`).
* **Unresolved ADR Status**: **`Deferred`** (`ADR-008`).
* **Unblocking Required Evidence**: Message throughput (msg/sec), queue depth, and payload size metrics (`OPEN-001`).
* **Environment Topology**: 3-node Erlang cluster deployed across AZ-a, AZ-b, and AZ-c.
* **High Availability Model**: Quorum Queues replicated across 3 nodes (`NFR-001`).
* **Backup Method**: Velero EKS state volume backups + RabbitMQ definitions JSON export (`ADR-013`).
* **Monitoring & Alerts**: Prometheus `rabbitmq_queue_messages_ready` and `rabbitmq_erlang_mem_limit` alerts.
* **Scaling Method**: Dynamic pod replica expansion + EBS `gp3` storage auto-scaling.
* **Upgrade Method**: Rolling pod StatefulSet replacement via RabbitMQ Operator.
* **Failure Recovery**: Quorum queue leader re-election upon node crash.
* **Data Migration Requirements**: Re-declaring exchange and queue definitions via Ansible (`FUN-004`).

---

### 2.4 MongoDB Document Database (`FUN-007`)
* **Proposed / Candidate Deployment Model**: MongoDB Operator on EKS vs. MongoDB Atlas vs. Amazon DocumentDB (`ADR Candidate: ADR-009`).
* **Unresolved ADR Status**: **`Deferred`** (`ADR-009`).
* **Unblocking Required Evidence**: **MANDATORY AUDIT of application queries against DocumentDB wire-protocol compatibility** (`RSK-DAT-001`).
* **Environment Topology**: 3-member Replica Set (1 Primary, 2 Secondaries) across 3 AZs.
* **High Availability Model**: Automatic replica set election (< 15 seconds) upon primary failure.
* **Backup Method**: Daily volume snapshots + oplog continuous archiving for 30-day PITR (`ADR-013`).
* **Monitoring & Alerts**: MongoDB exporter `opcounter`, `asserts`, and `mem_resident` alerts.
* **Scaling Method**: Vertical node resizing + MongoDB sharding.
* **Upgrade Method**: Rolling replica set member upgrade (Secondaries first, Primary last).
* **Failure Recovery**: Automated secondary member election.
* **Data Migration Requirements**: `mongodump` / `mongorestore` or MongoDB Relocate tool.

---

### 2.5 Nacos Service Discovery & Dynamic Configuration (`FUN-009`)
* **Proposed / Candidate Deployment Model**: Nacos Cluster StatefulSet on EKS (`ADR-010`).
* **Unresolved ADR Status**: **`Proposed`** (`ADR-010`).
* **Environment Topology**: 3-node Nacos Raft cluster deployed across AZ-a, AZ-b, and AZ-c in Private Application Subnets.
* **High Availability Model**: Nacos Raft consensus quorum backed by the MySQL relational database tier.
* **Backup Method**: Nacos configuration data backed up via MySQL database snapshots (`ADR-013`).
* **Monitoring & Alerts**: Nacos actuator health metrics + MySQL connection pool tracking.
* **Scaling Method**: Horizontal pod replica scaling (`3` → `5` nodes).
* **Upgrade Method**: Rolling StatefulSet image update.
* **Failure Recovery**: Nacos Raft leader re-election.
* **Data Migration Requirements**: Nacos configuration export/import zip archives.
