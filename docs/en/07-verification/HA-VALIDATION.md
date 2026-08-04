# High Availability Validation Plan: DataBlue Next-Gen Infrastructure Platform

---

## 1. Overview

This document specifies the **High Availability (HA) & Fault Tolerance Validation Plan** for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

In accordance with requirement [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md):
* High availability guarantees are validated via simulated node crashes, pod evictions, and Availability Zone network outages.
* **No test results are pre-marked as passed**. All HA validation items are currently in `Pending` status.

---

## 2. High Availability Validation Matrix

| HA Layer | Governing Requirement / ADR | Validation Audit Scope | Target Acceptance Pass Criteria | Mandatory Evidence ID | Responsible Owner | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Control Plane HA** | [`ADR-003`](../03-decisions/ADR-003-kubernetes-platform.md) | AWS EKS managed control plane multi-AZ etcd quorum | EKS API server available during single AZ outage | `EVD-HA-001` | Cloud Architect | `Pending` |
| **2. Worker Node HA** | [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-005`](../03-decisions/ADR-005-node-autoscaling.md) | EC2 worker nodes distributed across 3 AZs | Node pools balanced across AZ-a, AZ-b, & AZ-c | `EVD-HA-001` | SRE Lead | `Pending` |
| **3. Pod Topology Spread**| [`NFR-001`](../01-requirements/REQUIREMENTS-REGISTER.md) | Pod Topology Spread Constraints (`topologyKey`) | Application pods distributed evenly across 3 AZs | `EVD-HA-001` | DevOps Lead | `Pending` |
| **4. MySQL Database HA** | [`FUN-005`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-006`](../03-decisions/ADR-006-mysql-deployment.md) | Amazon RDS MySQL Multi-AZ primary instance termination | Automated failover to standby instance (< 60s) | `EVD-HA-002` | DBA Lead | `Pending` |
| **5. Redis Cache HA** | [`FUN-008`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-007`](../03-decisions/ADR-007-redis-deployment.md) | ElastiCache Redis replication primary node failover | Automatic primary failover & endpoint update (< 30s) | `EVD-HA-003` | Infrastructure Lead | `Pending` |
| **6. RabbitMQ Broker HA** | [`FUN-006`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-008`](../03-decisions/ADR-008-rabbitmq-deployment.md) | RabbitMQ 3-node Quorum Queue leader termination | Quorum queue leader re-election with zero data loss | `EVD-MQ-001` | App Architect | `Pending` |
| **7. Nacos Cluster HA** | [`FUN-009`](../01-requirements/REQUIREMENTS-REGISTER.md), [`ADR-010`](../03-decisions/ADR-010-nacos-deployment.md) | Nacos Raft cluster node termination | Raft leader re-election & config availability | `EVD-NC-001` | App Architect | `Pending` |

---

## 3. High Availability Fault Injection Test Protocols

### Test HA-01 — Availability Zone Blackhole Simulation
* **Procedure**: Inject AWS Fault Injection Simulator (FIS) network disruption blackholing all inbound/outbound traffic to Availability Zone `AZ-a`.
* **Pass Criteria**:
  1. EKS pod replicas in `AZ-b` and `AZ-c` handle 100% of ingress traffic.
  2. ALB health checks remove `AZ-a` targets within 15 seconds.
  3. Zero user-facing transaction loss (`EVD-HA-001`).

### Test HA-02 — Multi-AZ MySQL Master Failover Drill
* **Procedure**: Trigger forced reboot with failover on RDS MySQL primary database instance (`FUN-005`).
* **Pass Criteria**: Standby instance in secondary AZ promoted to Primary; CNAME DNS endpoint updated; microservice pods reconnect automatically within < 60 seconds (`EVD-HA-002`).
