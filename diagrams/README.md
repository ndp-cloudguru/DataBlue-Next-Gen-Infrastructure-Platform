# Architecture Diagrams Directory: DataBlue Next-Gen Infrastructure Platform

This directory contains all the standalone Mermaid architecture diagrams (`.mmd`) and their compiled **PNG** and **SVG** graphic formats for the **DataBlue Next-Gen Infrastructure Platform** (`datablue-nextgen-infra-platform`).

---

## 📁 Diagram Inventory & Rendered Artifacts

| Diagram Title & Scope | Mermaid Source (`src/`) | Vector Graphics (`svg/`) | Bitmap Image (`png/`) |
| :--- | :--- | :--- | :--- |
| **01. Requirements Baseline** | [`01_requirements_baseline.mmd`](src/01_requirements_baseline.mmd) | [`01_requirements_baseline.svg`](svg/01_requirements_baseline.svg) | [`01_requirements_baseline.png`](png/01_requirements_baseline.png) |
| **02. Master 5-Layer Platform Architecture** | [`02_master_5layer_architecture.mmd`](src/02_master_5layer_architecture.mmd) | [`02_master_5layer_architecture.svg`](svg/02_master_5layer_architecture.svg) | [`02_master_5layer_architecture.png`](png/02_master_5layer_architecture.png) |
| **03. Landing Zone Multi-Account** | [`03_landing_zone_multi_account.mmd`](src/03_landing_zone_multi_account.mmd) | [`03_landing_zone_multi_account.svg`](svg/03_landing_zone_multi_account.svg) | [`03_landing_zone_multi_account.png`](png/03_landing_zone_multi_account.png) |
| **04. Overall Platform Connectivity** | [`04_overall_platform_connectivity.mmd`](src/04_overall_platform_connectivity.mmd) | [`04_overall_platform_connectivity.svg`](svg/04_overall_platform_connectivity.svg) | [`04_overall_platform_connectivity.png`](png/04_overall_platform_connectivity.png) |
| **05. LLD Ingress & Pod Scaling** | [`05_lld_ingress_pod_scaling.mmd`](src/05_lld_ingress_pod_scaling.mmd) | [`05_lld_ingress_pod_scaling.svg`](svg/05_lld_ingress_pod_scaling.svg) | [`05_lld_ingress_pod_scaling.png`](png/05_lld_ingress_pod_scaling.png) |
| **06. LLD CI/CD & GitOps Pipeline** | [`06_lld_cicd_gitops_pipeline.mmd`](src/06_lld_cicd_gitops_pipeline.mmd) | [`06_lld_cicd_gitops_pipeline.svg`](svg/06_lld_cicd_gitops_pipeline.svg) | [`06_lld_cicd_gitops_pipeline.png`](png/06_lld_cicd_gitops_pipeline.png) |
| **07. LLD Stateful DB & Secrets** | [`07_lld_stateful_db_secrets.mmd`](src/07_lld_stateful_db_secrets.mmd) | [`07_lld_stateful_db_secrets.svg`](svg/07_lld_stateful_db_secrets.svg) | [`07_lld_stateful_db_secrets.png`](png/07_lld_stateful_db_secrets.png) |
| **08. LLD Observability & Logging** | [`08_lld_observability_logging.mmd`](src/08_lld_observability_logging.mmd) | [`08_lld_observability_logging.svg`](svg/08_lld_observability_logging.svg) | [`08_lld_observability_logging.png`](png/08_lld_observability_logging.png) |
| **09. Implementation Roadmap Phases** | [`09_implementation_roadmap_phases.mmd`](src/09_implementation_roadmap_phases.mmd) | [`09_implementation_roadmap_phases.svg`](svg/09_implementation_roadmap_phases.svg) | [`09_implementation_roadmap_phases.png`](png/09_implementation_roadmap_phases.png) |
| **10. FinOps Cost Scenarios Overview** | [`10_finops_cost_scenarios.mmd`](src/10_finops_cost_scenarios.mmd) | [`10_finops_cost_scenarios.svg`](svg/10_finops_cost_scenarios.svg) | [`10_finops_cost_scenarios.png`](png/10_finops_cost_scenarios.png) |
| **11. Scenario 1 Architecture (Test)** | [`scenario1_cost_architecture.mmd`](src/scenario1_cost_architecture.mmd) | [`scenario1_cost_architecture.svg`](svg/scenario1_cost_architecture.svg) | [`scenario1_cost_architecture.png`](png/scenario1_cost_architecture.png) |
| **12. Scenario 2 Architecture (Prod Baseline)**| [`scenario2_cost_architecture.mmd`](src/scenario2_cost_architecture.mmd) | [`scenario2_cost_architecture.svg`](svg/scenario2_cost_architecture.svg) | [`scenario2_cost_architecture.png`](png/scenario2_cost_architecture.png) |
| **13. Scenario 3 Architecture (Prod HA)** | [`scenario3_cost_architecture.mmd`](src/scenario3_cost_architecture.mmd) | [`scenario3_cost_architecture.svg`](svg/scenario3_cost_architecture.svg) | [`scenario3_cost_architecture.png`](png/scenario3_cost_architecture.png) |
| **14. Scenario 4 Architecture (Cross-Region DR)**| [`scenario4_cost_architecture.mmd`](src/scenario4_cost_architecture.mmd) | [`scenario4_cost_architecture.svg`](svg/scenario4_cost_architecture.svg) | [`scenario4_cost_architecture.png`](png/scenario4_cost_architecture.png) |

---

## 🛠️ Automated Rendering Script (`render.py` / `render.sh`)

To extract and re-render all diagrams after modifying Markdown documentation or `.mmd` source files:
```bash
python3 diagrams/render.py
```
or:
```bash
./diagrams/render.sh
```
This script automatically:
1. Extracts all Mermaid code blocks from markdown documentation in `docs/en/`.
2. Compiles `.mmd` files into high-resolution **PNG** (`png/`) and **SVG** (`svg/`) using `@mermaid-js/mermaid-cli`.
