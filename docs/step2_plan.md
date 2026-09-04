# Roadmap de Evolución del POC: Data Engineering & CI/CD Platform

Este documento detalla la evolución estratégica del Proof of Concept (POC). El objetivo es extender las capacidades del pipeline analítico y del motor de CI/CD semántico sobre plataformas Cloud Enterprise (**Microsoft Fabric** y **Snowflake**), integrando orquestación avanzada y convivencia con estándares de la industria como **dbt**.

---

## 🎯 Objetivos Principales
1. **Atender la demanda prioritaria de negocio:** Entregar un modelo de CI/CD multi-entorno para Microsoft Fabric.
2. **Escalar el motor de transformación:** Migrar SQLMesh de DuckDB a Snowflake para aprovechar arquitecturas de clonado virtual y costo optimizado.
3. **Fomentar la interoperabilidad:** Demostrar cómo integrar ingestas nativas (Dynamic Tables) y modelos dbt heredados bajo un gobierno unificado con SQLMesh.
4. **Gobierno y Orquestación Enterprise:** Consolidar el linaje, monitoreo y ejecución end-to-end mediante Dagster.

---

## 🗺️ Fases del Plan de Trabajo

### **Fase 1: CI/CD Pipeline para Microsoft Fabric (Cliente Prioritario)**
> **Objetivo:** Implementar un flujo automatizado de despliegue y promoción entre entornos para artefactos analíticos en Fabric.

* **1.1. Configuración de Repositorios y Entornos:**
  * Vincular el repositorio de GitHub con los Workspaces de Fabric (**DEV**, **UAT** y **PROD**).
  * Definir la estructura de ramas y políticas de protección (`main`, `release`, `feature/*`).
* **1.2. Pipeline de CI (Continuous Integration):**
  * Creación de GitHub Action para validación de sintaxis, reglas de estilo (*linting*) y tests unitarios en cada *Pull Request* hacia `DEV`.
  * Generación automática de resumen de cambios para revisores.
* **1.3. Pipeline de CD (Continuous Deployment):**
  * Despliegue automatizado hacia el Workspace de **DEV**.
  * Configuración de la API de Fabric / deployment pipelines con **gateways de aprobación manual** (Environment Protection Rules) para la promoción hacia **UAT** y **PROD**.

* **Entregables:** Workflows de GitHub Actions configurados y documentación de promoción entre Workspaces.
* **Valor para el Evaluador:** Demuestra gobierno, trazabilidad y control de cambios en la plataforma líder de Microsoft.

---

### **Fase 2: Migración de SQLMesh a Snowflake & Virtual Environments**
> **Objetivo:** Evolucionar el motor de transformación analítica de una base embebida (DuckDB) a un Data Warehouse empresarial (Snowflake).

* **2.1. Configuración de Conexión y Estado:**
  * Configurar la conexión de SQLMesh hacia Snowflake y migrar el *State Store* de SQLMesh a Snowflake.
  * Adaptar los dialectos y la sintaxis SQL de los modelos existentes (capas Bronze, Silver, Gold).
* **2.2. Implementación de Virtual Data Marts:**
  * Configurar el aislamiento de entornos utilizando las capacidades de *Zero-Copy Cloning* y vistas dinámicas de Snowflake.
  * Modificar el CI de GitHub Actions para que cada PR levante un entorno virtual efímero en Snowflake sin duplicación física de datos ni costos adicionales de almacenamiento.
* **2.3. Auditorías y Tests Semánticos:**
  * Mapear y ejecutar los *Audits* y *Tests* nativos de SQLMesh sobre la capa de Snowflake antes de autorizar el *merge*.

* **Entregables:** Proyecto SQLMesh corriendo nativamente en Snowflake con entornos virtuales en CI/CD.
* **Valor para el Evaluador:** Muestra reducción drástica de costos de cómputo/almacenamiento en pruebas de CI/CD.

---

### **Fase 3: Ingesta Híbrida (Snowflake Dynamic Tables + SQLMesh)**
> **Objetivo:** Combinar patrones de ingesta Near-Real-Time en Snowflake con transformaciones analíticas avanzadas.

* **3.1. Ingesta Bronze vía Dynamic Tables (DFM):**
  * Crear/Configurar una **Dynamic Table** en Snowflake para procesar datos continuos hacia la capa Bronze/Raw.
* **3.2. Integración y Modelado en SQLMesh:**
  * Definir la Dynamic Table como modelo externo (*external model*) dentro de SQLMesh.
  * Construir las transformaciones de capa Silver y Gold en SQLMesh consumiendo directamente la Dynamic Table.
* **3.3. Monitoreo de Dependencias:**
  * Validar la propagación de cambios y refrescos entre la capa de ingesta continua de Snowflake y las transformaciones batch de SQLMesh.

* **Entregables:** Pipeline híbrido donde Snowflake maneja la ingesta reactiva y SQLMesh la lógica de negocio/modelado.
* **Valor para el Evaluador:** Ofrece una arquitectura moderna que aprovecha lo mejor de las funciones nativas del motor y el control de la capa de transformación.

---

### **Fase 4: Interoperabilidad con dbt desde SQLMesh**
> **Objetivo:** Demostrar cómo incorporar proyectos o modelos existentes desarrollados en dbt dentro del flujo de SQLMesh sin necesidad de reescritura.

* **4.1. Importación e Integración del Módulo dbt:**
  * Importar un proyecto/módulo de dbt al repositorio mediante las capacidades nativas de SQLMesh (`sqlmesh init -m dbt`).
* **4.2. Ejecución y Verificación:**
  * Configurar SQLMesh para que orqueste, compile y ejecute los modelos de dbt apuntando a Snowflake.
* **4.3. Extensión de CI/CD Semántico a dbt:**
  * Aplicar el análisis semántico de impacto de SQLMesh sobre los modelos de dbt durante la apertura de Pull Requests.

* **Entregables:** Módulo dbt conviviendo y ejecutándose bajo la infraestructura de control y CI/CD de SQLMesh.
* **Valor para el Evaluador:** Protege la inversión técnica previa en dbt agregando gobernanza sin costos de licenciamiento de dbt Cloud.

---

### **Fase 5: Orquestación End-to-End con Dagster**
> **Objetivo:** Unificar la orquestación, el monitoreo operativo y la visibilidad del linaje de datos de todo el ecosistema.

* **5.1. Definición de Software-Defined Assets (SDAs):**
  * Integrar Dagster con SQLMesh (y los modelos de dbt/Snowflake) utilizando conectores nativos.
* **5.2. Pipeline Unificado:**
  * Crear un DAG en Dagster que controle la secuencia completa: *Trigger de Ingesta -> Ejecución de SQLMesh -> Disparo/Refresco de Artefactos en Fabric*.
* **5.3. Observabilidad y Linaje:**
  * Configurar el panel de Dagster para visualizar el linaje de datos unificado, alertas de fallos y métricas de ejecución.

* **Entregables:** Servidor/Instancia de Dagster orquestando el flujo completo con linaje centralizado.
* **Valor para el Evaluador:** Proporciona una visión de nivel de producción (*Enterprise Ready*) para la operación diaria de ingenieros y analistas.

---

## 📌 Resumen de Cobertura para los Evaluadores

| Evaluador / Perfil | Necesidad Identificada | Solución en el Plan |
| :--- | :--- | :--- |
| **Sponsor / Cliente Principal** | CI/CD y despliegue automatizado en **Fabric** | **Fase 1** (Entornos DEV/UAT/PROD con aprobaciones). |
| **Evaluador Técnico (SQLMesh)** | Transformación gratuita, eficiente y con control de impacto | **Fases 2, 3 y 4** (SQLMesh sobre Snowflake + Virtual Data Marts). |
| **Evaluador de Infra/Snowflake** | Reutilización de inversiones en **Snowflake & dbt** | **Fases 3 y 4** (Dynamic Tables + Compatibilidad nativa dbt). |
| **Líder de Operaciones / Arquitectura** | Observabilidad, monitoreo y control operacional | **Fase 5** (Orquestación unificada con Dagster). |