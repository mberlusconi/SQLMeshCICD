MODEL (
  name demo.daily_sales,
  kind FULL,
  cron '@daily'
);

SELECT
  transaction_date,
  COUNT(DISTINCT transaction_id) AS total_transactions,
  COUNT(DISTINCT customer_id) AS unique_customers,
  SUM(amount) AS total_revenue,
  AVG(amount) AS avg_ticket_size
FROM demo.core_transactions
GROUP BY
  transaction_date;