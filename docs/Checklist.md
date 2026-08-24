# 🚀 Checklist de Demostración: Pipelines de Datos y CI/CD con SQLMesh & GitHub Actions

## 📋 Fase 1: Preparación del Entorno Local (Data Pipeline)
- [x] **1.1. Verificar Estructura de Proyectos y Datos**
  - [x] Validar archivos en `sources/transactions/` (del 17 al 24 de agosto).
  - [x] Verificar que `transactions_2026-08-22.csv` tenga solo los 12 registros válidos (eliminar las 3 filas corruptas).
- [ ] **1.2. Construcción de Modelos del Proyecto**
  - [x] `models/staging/stg_transactions.sql` (Capa Staging / Incremental por fecha).
  - [x] `models/core/core_transactions.sql` (Capa Core / Transacciones enriquecidas).
  - [x] `models/morts/daily_sales.sql` (Capa Marts / Agregaciones de ventas diarias).
  - [x] `audits/assert_valid_transactions.sql` (Auditoría de calidad).
- [x] **1.3. Inicializar Entorno de Producción Base**
  - [x] Ejecutar el plan inicial para poblar `prod`:
    ```bash
    sqlmesh plan --auto-apply
    ```
  - [x] Verificar en DuckDB que las tablas y vistas apunten al entorno de producción de forma limpia.

---

## 🔬 Fase 2: Demostración de AislaMiento y Calidad (Virtual Environments)
- [x] **2.1. Simular Cambio / Error en Entorno Aislado (`dev`)**
  - [x] Agregar un registro corrupto en un CSV o modificar un modelo de prueba.
  - [x] Crear / Ejecutar el plan sobre el entorno `dev`:
    ```bash
    sqlmesh plan dev
    ```
  - [x] **Demostrar el bloqueo:** La auditoría debe fallar en el entorno `dev` sin impactar la vista o tabla de `prod`.
  - [x] Consultar DuckDB en `sales_analytics.stg_transactions` y demostrar que la versión de producción sigue 100% limpia.
- [x] **2.2. Corrección y Promoción Virtual**
  - [x] Corregir los datos/código defectuosos.
  - [x] Re-ejecutar el plan en `dev`:
    ```bash
    sqlmesh plan dev --auto-apply
    ```
  - [x] Promover los cambios a Producción mediante Virtual Update (sin recalcular físicamente datos innecesarios):
    ```bash
    sqlmesh plan --auto-apply
    ```

---

## 🛠️ Fase 3: Configuración e Integración CI/CD (Pipeline de Código con GitHub Actions)
- [ ] **3.1. Preparar Repositorio GitHub**
  - [ ] Inicializar Git (`git init`, `git add .`, `git commit`).
  - [ ] Crear repositorio remoto en GitHub y vincularlo (`git remote add origin ...`).
- [ ] **3.2. Configurar Workflow de CI/CD**
  - [ ] Crear el directorio de workflows: `.github/workflows/sqlmesh.yml`.
  - [ ] Configurar los pasos de la GitHub Action:
    - [ ] Checkout del código.
    - [ ] Configuración de Python y dependencias (`sqlmesh`, `duckdb`, etc.).
    - [ ] Ejecución de tests unitarios de SQLMesh (`sqlmesh test`).
    - [ ] Creación de entorno virtual dinámico por Pull Request (`sqlmesh plan pr_<number>`).
- [ ] **3.3. Configurar Secretos / Artefactos**
  - [ ] Configurar persistencia del estado (o base de datos para la demo en CI).

---

## 🎬 Fase 4: Demostración Final End-to-End (Demo Live)
- [ ] **4.1. Abrir un Pull Request (PR)**
  - [ ] Crear una rama nueva (`git checkout -b feature/nuevos-marts`).
  - [ ] Modificar o agregar una métrica en la capa Marts (`daily_sales.sql`).
  - [ ] Hacer `push` y abrir el Pull Request en GitHub.
- [ ] **4.2. Validación Automática en PR (CI)**
  - [ ] Mostrar cómo GitHub Actions ejecuta el pipeline de pruebas y auditoría en un entorno Virtual aislado correspondiente a la PR.
- [ ] **4.3. Merge & Deploy Automático (CD)**
  - [ ] Hacer Merge del PR a la rama `main`.
  - [ ] Mostrar cómo el pipeline de producción aplica el Virtual Update instantáneo en `prod`.

---

## Apéndice: Patrón de Ingesta Aislada (Raw / Landing Layer)

> **Propósito:** Guía de evolución a producción para desacoplar la ingesta física de archivos locales. Permite que las auditorías de SQLMesh actúen como un filtro transaccional completo, protegiendo también la capa *Staging* (Bronze) ante la llegada de archivos de origen corruptos.

### 1. Ingesta a Capa Raw (Extract & Load)
En lugar de permitir que SQLMesh consulte directamente los archivos del sistema mediante `read_csv_auto()`, los datos de origen se persisten primero en un esquema inmutable de aterrizaje:

```sql
-- Ejecutar en la CLI de DuckDB (simulando el job de ingesta)
CREATE SCHEMA IF NOT EXISTS raw;

CREATE OR REPLACE TABLE raw.transactions AS 
SELECT * FROM read_csv_auto('sources/transactions/transactions_*.csv');

```

### 2. Refactor del Modelo Staging (`models/staging/stg_transactions.sql`)
Se actualiza el origen del modelo de Staging para consumir la tabla persistente `raw.transactions`:

```sql
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
FROM raw.transactions
WHERE transaction_date BETWEEN @start_date AND @end_date;
```

### 3.Ejecución de la Prueba de Validación
Con el archivo con registros inválidos guardado en disco y cargado en `raw`:

```bash
sqlmesh plan --restate-model sales_analytics.stg_transactions --start 2026-08-22 --end 2026-08-22
```
### 4.Matriz de Verificación de Resultados

| Capa / Componente | Tabla / Vista | Resultado Esperado | Justificación DataOps |
| :--- | :--- | :--- | :--- |
| **Pipeline CLI** | Terminal | `FAIL / Aborted` | Aborto por auditoría `assert_valid_transactions`. |
| **Landing** | `raw.transactions` | 15 filas | Registro inmutable de auditoría del origen. |
| **Bronze** | `stg_transactions` | 12 filas | *Rollback* activo. Se descarta la tabla temporal antes del *swap*. |
| **Silver** | `core_transactions` | 12 filas | Ejecución omitida (`Skipped`). |
| **Gold** | `daily_sales` | 12 filas ($3,012.99) | Mantiene el estado consistente en capa analítica. |