{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

SELECT * FROM {{ source('walmart_databricks', 'orders') }}