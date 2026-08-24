MODEL (
  name sales_analytics.stg_transactions,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column transaction_date
  ),
  start '2026-08-17',
  cron '@daily',
  audits (assert_valid_transactions) 
);

SELECT
  CAST(transaction_id AS INT) AS transaction_id,
  CAST(customer_id AS VARCHAR) AS customer_id,
  CAST(transaction_date AS DATE) AS transaction_date,
  CAST(amount AS DECIMAL(10,2)) AS amount,
  CAST(currency AS VARCHAR) AS currency
FROM read_csv_auto('sources/transactions/transactions_*.csv')
WHERE
  CAST(transaction_date AS DATE) BETWEEN @start_date AND @end_date;