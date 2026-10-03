# Walmart Data Engineering Project

A modern, end-to-end data engineering pipeline that extracts retail transaction data from a transactional PostgreSQL database, loads it into Databricks (Data Lakehouse), transforms it using dbt, and orchestrates the entire workflow using Apache Airflow.

*Based on the YouTube Tutorial: [Data Engineering Project](https://youtu.be/ZEE-jNAthB0?si=ABQX_ApyBbGDD5SZ)*

---

## 🏗️ Architecture & Tech Stack

This project strictly follows the **Medallion Architecture** to process data from raw extraction to business-ready analytics.

### 1. Source Database (PostgreSQL / Neon)
Simulates a live OLTP (Online Transaction Processing) database.
- Hosted on **Neon Serverless Postgres**.
- Contains 6 core tables in the `raw` schema: `customers`, `stores`, `products`, `employees`, `orders`, and `order_items`.
- Managed locally via `walmart_dataset/load_data.py` (uses `psycopg2` and `python-dotenv` for seeding data).

### 2. Bronze Layer (Databricks)
- **Ingestion**: Raw data is ingested from Postgres directly into Databricks.
- **Orchestration**: Managed by an Airflow task (`ingest_cdc`), which securely triggers a Databricks Job using the Databricks Python SDK (`WorkspaceClient`).

### 3. Silver Layer (dbt - `walmart_proj`)
- **Silver Technical (`silver_t`)**: Cleanses raw data and materializes it **incrementally**. It tracks changes via `updated_timestamp` watermarking and appends a `processed_at` timestamp.
- **Silver Business (`silver_b`)**: Joins all 6 technical tables into a massive **One Big Table (OBT)** (`obt_b`) for simplified downstream analytics.

### 4. Gold Layer (dbt - `walmart_proj`)
- **Ephemeral Models (`gold/ephemeral`)**: Reusable CTEs/views configured as `ephemeral` to prevent unnecessary database storage.
- **Dimensions & Snapshots (`snapshots/`)**: Captures Slowly Changing Dimensions (SCDs) for entities like customers, stores, and products.
- **Fact Tables (`gold/fact`)**: Final, business-ready models like `fact_orders` for BI consumption.

### 5. Orchestration (Apache Airflow via Docker)
- Uses a custom **Docker Compose** setup (`apache/airflow:3.3.2` extended via Dockerfile).
- The primary DAG (`orchestrate.py`) executes the pipeline sequentially:
  `Ingest (Databricks) -> Clean dbt Target -> Source Freshness -> Silver Technical (+Tests) -> Silver Business (+Tests) -> Gold Ephemeral -> Gold Dimension Snapshots -> Gold Facts`.

---

## 📂 Project Structure

```text
├── walmart_dataset/                  # 1. Source data & database initialization
│   ├── ddl/walmart_schema.sql        # SQL DDL scripts to initialize Postgres schema
│   ├── data/                         # Raw CSV datasets
│   ├── .env.local                    # Postgres connection strings
│   └── load_data.py                  # Python script to load CSVs into Postgres/Neon
│
├── walmart_proj/                     # 2. dbt transformations (Data Build Tool)
│   ├── models/             
│   │   ├── silver_t/                 # Technical Silver Layer (Incremental models)
│   │   ├── silver_b/                 # Business Silver Layer (One Big Table)
│   │   └── gold/                     # Gold Layer (ephemeral models & facts)
│   ├── snapshots/                    # dbt Snapshots for Slowly Changing Dimensions (SCD)
│   ├── tests/                        # Custom dbt data tests
│   ├── dbt_project.yml               # dbt configuration and materialization rules
│   └── profiles.yml                  # Databricks connection profile
│
└── airflow_dbt_project/              # 3. Apache Airflow Orchestration
    ├── dags/orchestrate.py           # Master DAG controlling the pipeline sequence
    ├── Dockerfile                    # Custom Airflow image build 
    ├── docker-compose.yaml           # Docker setup mapped to local volumes
    └── requirements.txt              # Python dependencies (dbt-databricks, SQLAlchemy<2.1.0)
```

---

## 🚀 Getting Started

### 1. Source Database Setup (Postgres / Neon)
Ensure you have a PostgreSQL database running. Add your connection string to a `.env` file inside `walmart_dataset/`:
```env
POSTGRES_CONN_STRING="postgresql://<user>:<password>@<host>:5432/<db>?sslmode=require"
```
Run the ingestion script to create the `raw` schema and populate the dummy data:
```bash
cd walmart_dataset
python load_data.py
```

### 2. Set Up Airflow & Databricks Credentials
Airflow uses Docker to inject environment variables. Create an `.env` file inside the `airflow_dbt_project/` folder:
```env
# Required for Airflow to trigger Databricks Ingestion
DATABRICKS_HOST="https://dbc-b69236b5-ea92.cloud.databricks.com"
DBT_DATABRICKS_TOKEN="your_databricks_access_token_here"
DBT_JOB_ID="1234567890"  # The ID of your Databricks ingestion job
```
*Note: Make sure your `walmart_proj/profiles.yml` is also configured to read `DBT_DATABRICKS_TOKEN`.*

### 3. Start Airflow via Docker
Navigate to the Airflow directory and build the containers:
```bash
cd airflow_dbt_project
docker compose up -d --build
```
*Note: The `--build` flag is critical because the Dockerfile installs `dbt-databricks` and patches `SQLAlchemy` directly into the Airflow container.*

### 4. Run the Pipeline
1. Open the Airflow UI at `http://localhost:8080`.
2. Find the **`orchestrate`** DAG.
3. Toggle it on and trigger a run!
4. Watch as Airflow triggers the Databricks job, waits for success, and then perfectly cascades through the `silver_t`, `silver_b`, and `gold` dbt models.
