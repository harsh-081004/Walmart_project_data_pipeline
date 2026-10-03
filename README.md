# Walmart Data Engineering Project

A modern, end-to-end data engineering pipeline built using **PostgreSQL (Neon)**, **Databricks**, **dbt (data build tool)**, and orchestrated by **Apache Airflow**.

*Note: This project is based on [this Data Engineering Tutorial](https://youtu.be/ZEE-jNAthB0?si=ABQX_ApyBbGDD5SZ).*

---

## 🏗️ Architecture & Tech Stack

This project follows the **Medallion Architecture** (Bronze, Silver, Gold) to process and transform retail transaction data.

1. **Source Database (PostgreSQL / Neon)**
   - Simulates a live transactional database containing tables like `customers`, `stores`, `products`, `employees`, `orders`, and `order_items`.
2. **Bronze Layer (Databricks Ingestion)**
   - Raw data is ingested into Databricks via PySpark/Databricks Jobs directly from the Postgres database.
3. **Silver Layer (dbt)**
   - **Silver Technical (`silver_t`)**: Cleanses raw data and materializes it incrementally, tracking changes via watermarking (`processed_at`, `updated_timestamp`).
   - **Silver Business (`silver_b`)**: Joins and enriches the technical tables into a massive One Big Table (OBT) for downstream analytics.
4. **Gold Layer (dbt)**
   - **Dimensions & Facts**: Uses dbt `ephemeral` models and standard tables/snapshots to build clean Dimensional and Fact tables (`fact_orders`, `dim_customers`, etc.) ready for BI tools.
5. **Orchestration (Apache Airflow)**
   - A dockerized Airflow instance manages the entire pipeline, from triggering the Databricks ingestion job to running `dbt run` and `dbt test` in the correct dependency order.

---

## 📂 Project Structure

```text
├── walmart_dataset/        # Source data & schema setup
│   ├── ddl/                # SQL scripts to initialize Postgres schema
│   ├── data/               # Raw CSV files
│   └── load_data.py        # Python script to load CSVs into Postgres/Neon
│
├── walmart_proj/           # The dbt project for transformations
│   ├── models/             
│   │   ├── silver_t/       # Technical Silver Layer (Incremental)
│   │   ├── silver_b/       # Business Silver Layer (One Big Table)
│   │   └── gold/           # Gold Layer (Fact & Dimensions)
│   ├── dbt_project.yml     # dbt configuration file
│   └── profiles.yml        # Databricks connection profile
│
└── airflow_dbt_project/    # Airflow Orchestration
    ├── dags/               # Airflow DAGs (orchestrate.py)
    └── docker-compose.yaml # Docker setup for Airflow
```

---

## 🚀 Getting Started

### 1. Source Database Setup (Postgres / Neon)
Ensure you have a PostgreSQL database (like Neon) running. Add your connection string to the `.env` file at the root:
```env
POSTGRES_CONN_STRING="postgresql://<user>:<password>@<host>:5432/<db>?sslmode=require"
```
Navigate to `walmart_dataset/` and run the script to initialize the schema and populate the dummy data:
```bash
python load_data.py
```

### 2. Databricks & dbt Setup
Export your Databricks API token as an environment variable so dbt can authenticate:
```bash
export DBT_DATABRICKS_TOKEN="your_token_here"
```
*(Alternatively, place this in a `.env` file inside `walmart_proj/` if you are using an IDE extension like dbt Power User).*

To test the dbt models locally:
```bash
cd walmart_proj
dbt deps
dbt run
```

### 3. Airflow Orchestration
The entire pipeline is automated using Airflow. To start the Airflow cluster:
```bash
cd airflow_dbt_project
docker-compose up -d
```
Once Airflow is running, you can access the UI at `localhost:8080`, turn on the `orchestrate` DAG, and watch the data flow from ingestion to the Gold layer!
