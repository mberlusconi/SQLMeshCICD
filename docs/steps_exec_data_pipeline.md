## Steps to execute data pipeline from scratch

1. Remove all csv from ./sources/transactions except for the first one (transactions_20260817.csv). Renaming could also be a good idea if the is no other repository available.
```Text
    # ls  ./sources/transactions/
        transactions_20260817.csv  
        transactions_20260818.cv   
        transactions_20260819.cv   
        transactions_20260820.cv  
        transactions_20260821.cv  
        transactions_20260822.cv
        transactions_20260822.Error
        transactions_20260824.cv
```
2. Do a complete reset from previos executions and delete the existing duckdb database
```Text
    rm db/analytics.duckdb
    rm -rf .sqlmesh
```
3. Load the available csv files
```Text
    sqlmesh plan --auto-apply
```
4. Database check with duckdb
    * Open DB 
    ```Text
        duckdb ./db/analytics.duckdb
    ```
    * Check BRONZE layer
    ```SQL
        SELECT
            transaction_date,
            COUNT(*) AS transactions,
            SUM(amount) AS total_amount
        FROM sales_analytics.stg_transactions
        GROUP BY transaction_date
        ORDER BY transaction_date;
    ```
    ```Text
            ┌──────────────────┬──────────────┬───────────────┐
            │ transaction_date │ transactions │ total_amount  │
            │       date       │    int64     │ decimal(38,2) │
            ├──────────────────┼──────────────┼───────────────┤
            │ 2026-08-17       │            6 │        891.10 │
            └──────────────────┴──────────────┴───────────────┘
    ```
    * Check SILVER layer
    ```SQL
        SELECT transaction_date,
            ticket_segment,
            COUNT(*) AS transactions,
            SUM(amount) AS total_amount
        FROM sales_analytics.core_transactions
        GROUP BY transaction_date,
                ticket_segment
        ORDER BY transaction_date;
    ```
    ```Text
            ┌──────────────────┬────────────────┬──────────────┬───────────────┐
            │ transaction_date │ ticket_segment │ transactions │ total_amount  │
            │       date       │    varchar     │    int64     │ decimal(38,2) │
            ├──────────────────┼────────────────┼──────────────┼───────────────┤
            │ 2026-08-17       │ MEDIUM         │            3 │        676.40 │
            │ 2026-08-17       │ LOW            │            3 │        214.70 │
            └──────────────────┴────────────────┴──────────────┴───────────────┘
    ```
    * Check GOLD layer
    ```SQL
        SELECT 
            transaction_date, 
            total_transactions, 
            unique_customers, 
            total_revenue, 
            round(avg_ticket_size,2) AS avg_ticket
        FROM sales_analytics.daily_sales
        ORDER BY transaction_date;    
    ```
    ```Text
    ┌──────────────────┬────────────────────┬──────────────────┬───────────────┬────────────┐
    │ transaction_date │ total_transactions │ unique_customers │ total_revenue │ avg_ticket │
    │       date       │       int64        │      int64       │ decimal(10,2) │   double   │
    ├──────────────────┼────────────────────┼──────────────────┼───────────────┼────────────┤
    │ 2026-08-17       │                  6 │                5 │        891.10 │     148.52 │
    └──────────────────┴────────────────────┴──────────────────┴───────────────┴────────────┘
    ```
    * exit
    ```Text
        Ctrl + D
    ```
5. Adding another day 
   Enable or copy "transactions_20260818.csv" back into ´/sources/transactions´
   In a regular environment, where transaction files arrive one day at a time, the normal process is:
   ```Text
        sqlmesh plan --auto-apply
   ```
   The first time the process runs, SQLMesh creates an interval starting from the date of the first available file up to the current execution date.

   For example, if the first file is dated 2026-08-17 and the process is initially executed on 2026-08-28, SQLMesh may register the following interval:

   ```Text
        ┌─────────────────┬────────────┬────────────┬──────────────┬────────────────────────┐
        │      name       │ start_date │  end_date  │ is_compacted │ is_pending_restatement │
        │     varchar     │    date    │    date    │   boolean    │        boolean         │
        ├─────────────────┼────────────┼────────────┼──────────────┼────────────────────────┤
        │ stg_transactions│ 2026-08-17 │ 2026-08-28 │ false        │ false                  │
        └─────────────────┴────────────┴────────────┴──────────────┴────────────────────────┘

   ```
   You can verify the registered intervals with:
   ```SQL
        SELECT
            name,
            CAST(epoch_ms(start_ts) AS DATE) AS start_date,
            CAST(epoch_ms(end_ts) AS DATE) AS end_date,
            is_compacted,
            is_pending_restatement
        FROM sqlmesh._intervals
        WHERE name LIKE '%stg_transactions%'
        ORDER BY start_ts;
   ```
   In this situation, transactions_20260818.csv falls inside an interval that **SQLMesh has already processed**.
   Therefore, simply running the regular command again:
   ```Text
        sqlmesh plan --auto-apply
   ```
   will **not reprocess** the file, because SQLMesh considers that time range already processed. The regular incremental process is intended to discover and process new intervals after the existing end date.
   
   <ins>Solution</ins>:
    To process a file that belongs to an already-processed interval, we must explicitly request a **restate** of that interval.

    For example, to reprocess the interval containing **transactions_20260818.csv**:
   ```Text
        sqlmesh plan --restate-model sales_analytics.stg_transactions --start 2026-08-17 --end 2026-08-19 --auto-apply
   ```
   This tells SQLMesh to invalidate/restate the specified portion of the model's existing processed interval and rebuild it.

   The important point is that the `--start` and `--end` values define the time range to reprocess, not the filename itself.
   You can check with the same queries we used before 

6. Add all other files 
   Enable or copy all other *csv* back into */sources/transactions*. (Not the one marked as .Error) 
   ```Text
        sqlmesh plan --restate-model sales_analytics.stg_transactions --start 2026-08-17 --end 2026-08-25 --auto-apply
   ```
   Ready to run a full check using the *querys* showd before