# 🚀 Checklist de Demostración: Pipelines de Datos y CI/CD con SQLMesh & GitHub Actions

## 📋 Fase 1: Preparación del Entorno Local (Data Pipeline)
- [x] **1.1. Verificar Estructura de Proyectos y Datos**
  - [x] Validar archivos en `sources/transactions/` (del 17 al 24 de agosto).
  - [x] Verificar que `transactions_2026-08-22.csv` tenga solo los 12 registros válidos (eliminar las 3 filas corruptas).
- [ ] **1.2. Construcción de Modelos del Proyecto**
  - [x] `models/staging/stg_transactions.sql` (Capa Staging / Incremental por fecha).
  - [ ] `models/core/core_transactions.sql` (Capa Core / Transacciones enriquecidas).
  - [ ] `models/morts/daily_sales.sql` (Capa Marts / Agregaciones de ventas diarias).
  - [ ] `audits/assert_valid_transactions.sql` (Auditoría de calidad).
- [ ] **1.3. Inicializar Entorno de Producción Base**
  - [ ] Ejecutar el plan inicial para poblar `prod`:
    ```bash
    sqlmesh plan --auto-apply
    ```
  - [ ] Verificar en DuckDB que las tablas y vistas apunten al entorno de producción de forma limpia.

---

## 🔬 Fase 2: Demostración de AislaMiento y Calidad (Virtual Environments)
- [ ] **2.1. Simular Cambio / Error en Entorno Aislado (`dev`)**
  - [ ] Agregar un registro corrupto en un CSV o modificar un modelo de prueba.
  - [ ] Crear / Ejecutar el plan sobre el entorno `dev`:
    ```bash
    sqlmesh plan dev
    ```
  - [ ] **Demostrar el bloqueo:** La auditoría debe fallar en el entorno `dev` sin impactar la vista o tabla de `prod`.
  - [ ] Consultar DuckDB en `sales_analytics.stg_transactions` y demostrar que la versión de producción sigue 100% limpia.
- [ ] **2.2. Corrección y Promoción Virtual**
  - [ ] Corregir los datos/código defectuosos.
  - [ ] Re-ejecutar el plan en `dev`:
    ```bash
    sqlmesh plan dev --auto-apply
    ```
  - [ ] Promover los cambios a Producción mediante Virtual Update (sin recalcular físicamente datos innecesarios):
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