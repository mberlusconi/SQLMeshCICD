# Data Pipeline Architecture

## 1. Objective

Build a daily data pipeline that processes transaction files as they become available and uses SQLMesh to incrementally materialize the data.

The pipeline is intentionally separated from the software CI/CD process.

- **Data Pipeline** → responsible for processing data.
- **CI/CD Pipeline** → responsible for validating and deploying code changes.

---

## 2. High-Level Architecture

```text
                 Daily Source Files
                        │
                        ▼
              ┌───────────────────┐
              │   Data Storage    │
              │                   │
              │ transactions_     │
              │ YYYYMMDD.csv      │
              └─────────┬─────────┘
                        │
                        ▼
              ┌───────────────────┐
              │    Orchestrator   │
              │                   │
              │     Dagster       │
              └─────────┬─────────┘
                        │
                        │ Trigger / Schedule
                        ▼
              ┌───────────────────┐
              │      SQLMesh      │
              │                   │
              │ Incremental Model │
              └─────────┬─────────┘
                        │
                        ▼
              ┌───────────────────┐
              │      Staging      │
              │                   │
              │ stg_transactions  │
              └─────────┬─────────┘
                        │
                        ▼
              ┌───────────────────┐
              │       Core        │
              │                   │
              │   transactions    │
              └─────────┬─────────┘
                        │
                  ┌─────┴─────┐
                  ▼           ▼
          ┌─────────────┐ ┌──────────────┐
          │ daily_sales │ │customer_sales│
          └─────────────┘ └──────────────┘
```

## 3. Source Data

Transaction data arrives as daily CSV files.

Example:
```text
sources/
└── transactions/
    ├── transactions_20260817.csv
    ├── transactions_20260818.csv
    ├── transactions_20260819.csv
    ├── transactions_20260820.csv
    ├── transactions_20260821.csv
    └── transactions_20260824.csv
```
Each file represents a daily batch of transactions.

### Expected columns

```text
transaction_id
customer_id
transaction_date
amount
currency
```	        
The transaction_date column is the business date used by SQLMesh for incremental processing.

## 4. Data Pipeline Responsibilities

The data pipeline is responsible for:

1. Detecting or receiving notification that new source data is available.
2. Determining which business date(s) are available.
3. Triggering the corresponding SQLMesh processing.
4. Processing missing intervals.
5. Handling retries when execution fails.
6. Recording execution status.
7. Supporting historical backfills when required.
8. Providing operational visibility.

The pipeline is not responsible for validating code changes or deploying SQLMesh model definitions.

## 5. Orchestration

Dagster will be used as the data orchestrator.

The initial implementation will use a daily schedule.

```text
Daily Schedule
      │
      ▼
Check source availability
      │
      ├── Data available
      │       │
      │       ▼
      │   Run SQLMesh
      │
      └── Data unavailable
              │
              ▼
          Retry / Alert
```	        
A future implementation may replace the schedule with a file-based sensor.

## 6. SQLMesh Execution

The orchestrator invokes SQLMesh to process the data.

The primary operation is:

```Bash
sqlmesh run
```	        
SQLMesh determines which model intervals are ready or missing according to the model definition and its execution schedule.

The staging model uses:
```SQL
MODEL (
    name sales_analytics.stg_transactions,

    kind INCREMENTAL_BY_TIME_RANGE (
        time_column transaction_date
    ),

    start '2026-08-17',
    cron '@daily'
);
```

## 7. Incremental Processing

The pipeline processes data by business date rather than rebuilding the entire dataset.

Example:
```Text
  Initial load

  17 ────────┐
  18 ────────┤
  19 ────────┤
  20 ────────┤
  21 ────────┘
             │
             ▼
         SQLMesh
             │
             ▼
     Process required
        intervals
```
When a new daily file becomes available:
```Text
transactions_20260824.csv
             │
             ▼
       Orchestrator
             │
             ▼
          SQLMesh
             │
             ▼
       Process 2026-08-24
```
Previously processed intervals should not be unnecessarily rebuilt.

## 8. Historical Corrections

Historical data corrections are handled differently from normal daily processing.

Example:
```Text
transactions_20260820.csv
        │
        │ corrected
        ▼
Historical Restatement
        │
        ▼
     SQLMesh
        │
        ▼
Reprocess 2026-08-20
```
SQLMesh restatement can be performed with:
```Bash
sqlmesh plan \
  --restate-model sales_analytics.stg_transactions \
  --start 2026-08-20 \
  --end 2026-08-21
```
This allows a specific historical interval to be recalculated without rebuilding the entire model.

## Model Dependency Graph

The pipeline will eventually contain the following dependency graph:
```Text
                 Source Files
                      │
                      ▼
              stg_transactions
                      │
                      ▼
                 transactions
                 │          │
                 │          │
                 ▼          ▼
            daily_sales  customer_sales
```
SQLMesh manages dependencies between these models.

When an upstream interval is restated, affected downstream models can also be included in the required backfill.

## 10. Failure Handling

The orchestrator should handle failures independently from SQLMesh.

Example:
```Text
SQLMesh execution
       │
       ├── SUCCESS
       │      │
       │      ▼
       │   Mark run
       │   successful
       │
       └── FAILURE
              │
              ▼
          Retry
              │
              ├── SUCCESS
              │
              └── FAILURE
                     │
                     ▼
                   Alert
```
The pipeline should not silently mark a failed data load as successful.

## 11. Data Availability

The first implementation assumes that a daily file represents a completed batch.

For example:
```Text
transactions_20260824.csv
```
is considered ready for processing once the upstream process has completed the file.

The pipeline should avoid processing partially written files.

A future implementation may introduce:
* file sensors
* completion markers
* file manifests
* expected file counts
* data availability checks

## 12. Data Quality

Data quality checks will be implemented as part of the SQLMesh project.

Initial validations:
```Text
transaction_id IS NOT NULL
customer_id IS NOT NULL
transaction_date IS NOT NULL
amount >= 0
currency IS NOT NULL
```
The pipeline should fail or alert when critical data quality checks fail.


## 13. Observability

The orchestrator should provide visibility into:

* Pipeline execution status
* Start/end time
* Processed business date
* SQLMesh execution status
* Number of records processed
* Failed tasks
* Retry count
* Historical backfills

Example:
```Text 
Pipeline: daily_transactions

Business Date: 2026-08-24
Status: SUCCESS
Records: 5
SQLMesh: SUCCESS
Duration: 12 sec
```

## 14. Separation from CI/CD

The data pipeline and software pipeline are independent.

Data Pipeline
```Text
Source File
    │
    ▼
Dagster
    │
    ▼
SQLMesh Run
    │
    ▼
Data Warehouse
```
CI/CD Pipeline
```Text
Developer
    │
    ▼
Git Branch
    │
    ▼
Pull Request
    │
    ▼
GitHub Actions
    │
    ├── Tests
    ├── Lint
    └── SQLMesh Plan
    │
    ▼
Code Review
    │
    ▼
Merge
    │
    ▼
Production Deployment
```
The two pipelines interact through the deployed SQLMesh project, but they have different responsibilities.

## 15. Future Enhancements

The initial implementation should remain simple.

Possible future enhancements:

* Replace local CSV files with object storage.
* Replace scheduled execution with file sensors.
* Add data availability checks.
* Add automatic backfill detection.
* Add alerts.
* Add production environment.
* Add cloud data warehouse.
* Add CI/CD deployment.
* Add SQLMesh CI/CD Bot.
* Add lineage and observability.
* Add data contracts.

## 16. Target Architecture

The final target architecture is:
```Text
                         GitHub
                            │
                     Pull Request
                            │
                            ▼
                    GitHub Actions
                    ┌──────────────┐
                    │ Tests        │
                    │ Lint         │
                    │ SQLMesh Plan │
                    └──────┬───────┘
                           │
                         Merge
                           │
                           ▼
                      Production
                           │
                           │
                           ▼
                  ┌─────────────────┐
                  │     Dagster     │
                  │                 │
                  │ Schedule/Sensor │
                  └────────┬────────┘
                           │
                           ▼
                       SQLMesh
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
        Incremental                Backfill /
        Processing                 Restatement
              │                         │
              └────────────┬────────────┘
                           ▼
                    Data Warehouse
                           │
                    ┌──────┴──────┐
                    ▼             ▼
               daily_sales   customer_sales
```

## 17. Implementation Order

The implementation should follow this order:

 - [x] SQLMesh Quick Start
 - [x] Create clean SQLMesh project
 - [x] Create daily transaction source files
 - [x] Create incremental staging model
 - [x] Test daily incremental processing
 - [x] Test historical restatement
 - [x] Create transactions core model
 - [x] Create daily_sales mart
 - [x] Create customer_sales mart
 - [x] Add SQLMesh tests
 - [x] Initialize Git repository
 - [x] Create GitHub repository
 - [x] Implement GitHub Actions CI
 - [x] Implement SQLMesh plan in Pull Requests
 - [x] Implement production deployment
 - [ ] Introduce Dagster
 - [ ] Connect Dagster to SQLMesh
 - [ ] Add scheduling
 - [ ] Add failure/retry handling
 - [ ] Add observability
 - [x] Document the architecture
 - [ ] Convert repository into a reusable template