# DataBlue AWS Cost Analysis & Generator Package

This directory contains the master Python OpenPyXL cost generator and the generated multilingual Excel workbooks for the **DataBlue Next-Gen Infrastructure Platform**.

---

## 📁 Artifact Inventory

1. **`generate_cost_excel.py`**: Master Python OpenPyXL script that generates all 3 multilingual workbooks with 100% data consistency.
2. **`DataBlue_AWS_Cost_Analysis.xlsx`**: Detailed Vietnamese Scenario Cost Analysis Workbook.
3. **`DataBlue_AWS_Cost_Analysis_EN.xlsx`**: Detailed English Scenario Cost Analysis Workbook.
4. **`DataBlue_AWS_Cost_Analysis_CN.xlsx`**: Detailed Chinese Scenario Cost Analysis Workbook.

---

## 📊 Workbook Structure (8 Sheets Per File)

Each Excel workbook contains 8 fully formatted sheets:

1. **📊 Executive Summary / Tóm tắt Tổng quan**: High-level comparison card dashboard & scenario metrics overview.
2. **📌 SC1 Test Non-Prod**: Detailed itemized bill for Scenario 1 (QA/UAT Testing Environment).
3. **📌 SC2 Production Baseline**: Detailed itemized bill for Scenario 2 (Initial Production Deployment).
4. **📌 SC3 Production HA**: Detailed itemized bill for Scenario 3 (Enhanced High Availability Production).
5. **📌 SC4 Cross-Region DR**: Detailed itemized bill for Scenario 4 (Primary us-east-1 + Pilot Light us-west-2 DR).
6. **📌 SC5 Enterprise Multi-Account**: Detailed itemized bill for Scenario 5 (5 Isolated AWS Accounts Architecture).
7. **📈 Cost Comparison / So sánh Chi phí**: Comparative charts & monthly/annualized cost conversion tables.
8. **📋 Assumptions & Pricing / Giả định & Đơn giá**: 50 itemized AWS public rate benchmarks across Compute, Database, Network, Storage, Security & APM.

---

## ⚙️ How to Regenerate Workbooks

To update prices, quantities, or component notes and regenerate all 3 Excel workbooks:

```bash
python3 cost_summary/generate_cost_excel.py
```

### Requirements:
- Python 3.8+
- `openpyxl` library (`pip install openpyxl`)
