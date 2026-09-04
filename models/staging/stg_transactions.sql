MODEL (
  name demo.stg_transactions,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column transaction_date
  ),
  start '2026-08-17'
);

WITH source_data AS (
  SELECT
    CAST("$1" AS INT) AS transaction_id,
    CAST("$2" AS VARCHAR) AS customer_id,
    CAST("$3" AS DATE) AS transaction_date,
    CAST("$4" AS DECIMAL(10, 2)) AS amount,
    CAST("$5" AS VARCHAR) AS currency
  FROM @stage_source()
)
SELECT
  transaction_id,
  customer_id,
  transaction_date,
  amount,
  currency
FROM source_data
WHERE
  transaction_date BETWEEN @start_date AND @end_date