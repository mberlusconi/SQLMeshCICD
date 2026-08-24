AUDIT (
  name assert_valid_transactions
);

SELECT
  transaction_id,
  customer_id,
  amount
FROM @this_model
WHERE
  amount <= 0
  OR transaction_id IS NULL
  OR customer_id IS NULL;