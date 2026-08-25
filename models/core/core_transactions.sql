MODEL (
  name sales_analytics.core_transactions,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column transaction_date
  ),
  start '2026-08-17',
  cron '@daily'
);

SELECT
  transaction_id,
  customer_id,
  transaction_date,
  amount,
  currency,
  CASE 
    WHEN amount >= 300 THEN 'HIGH'
    WHEN amount >= 100 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS ticket_segment
FROM sales_analytics.stg_transactions
WHERE
  transaction_date BETWEEN @start_date AND @end_date;