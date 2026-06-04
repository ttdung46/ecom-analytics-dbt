# E-Commerce Analytics Pipeline

A local data engineering project that ingests raw e-commerce event data, transforms it through a layered dbt pipeline, and produces analytics-ready datamarts — all running on DuckDB.

## Tech Stack

| Layer | Tool |
|-------|------|
| Ingestion | Python + gdown + PyArrow |
| Storage | DuckDB + Parquet |
| Transformation | dbt-core + dbt-duckdb |
| Package manager | uv |

---

## Architecture

```
Google Drive (CSV)
      │
      ▼
gdrive_to_parquet.py          # stream CSV → Parquet (no temp file)
      │
      ▼
data.parquet                  # ~67M event rows (zstd compressed)
      │
      ▼ dbt run
┌─────────────────────────────────────────┐
│  STAGING (view)                         │
│  stg_events            stg_purchase_behavior │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│  TRANSFORM (table)                      │
│  dim_users   dim_products               │
│  dim_categories   dim_dates             │
│  fact_events (view — disk constraint)   │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│  DATAMART (table)                       │
│  dm_product_performance                 │
│  dm_category_analysis                   │
│  dm_customer_rfm                        │
│  dm_customer_ltv                        │
│  dm_user_cohort                         │
│  dm_behavior_by_hour                    │
└─────────────────────────────────────────┘
```

---

## Datamarts

| Model | Mô tả |
|-------|-------|
| `dm_product_performance` | Views, carts, purchases, revenue, conversion rate theo sản phẩm |
| `dm_category_analysis` | Doanh thu và tỷ lệ chuyển đổi theo ngành hàng |
| `dm_customer_rfm` | Phân khúc khách hàng: Champions / Loyal / At Risk / Lost |
| `dm_customer_ltv` | Lifetime Value ước tính theo từng user |
| `dm_user_cohort` | Cohort retention theo tuần |
| `dm_behavior_by_hour` | Hành vi mua sắm theo khung giờ và ngày trong tuần |

---

## Quickstart

**1. Clone và cài dependencies**
```bash
git clone https://github.com/ttdung46/ecom-analytics-dbt
cd ecom-analytics-dbt
uv sync
```

**2. Tải data từ Google Drive**
```bash
uv run python gdrive_to_parquet.py
```

**3. Cài dbt packages**
```bash
uv run dbt deps
```

**4. Chạy pipeline**
```bash
uv run dbt run
```

**5. Kiểm tra data quality**
```bash
uv run dbt test
```

**6. Xem lineage graph và documentation**
```bash
uv run dbt docs generate && uv run dbt docs serve
# Mở http://localhost:8080
```

---

## Data Quality

16 tests được định nghĩa và pass toàn bộ:
- `unique` + `not_null` trên các surrogate keys
- `accepted_values` cho `event_type`
- Dedup logic trên `fact_events` via `QUALIFY ROW_NUMBER()`

---

## Project Structure

```
ecom-analytics-dbt/
├── models/
│   ├── staging/        # Raw source → cast, rename, filter
│   ├── transform/      # Dimensions + fact table
│   └── datamart/       # Analytics-ready aggregates
├── gdrive_to_parquet.py
├── dbt_project.yml
├── packages.yml
└── pyproject.toml
```
