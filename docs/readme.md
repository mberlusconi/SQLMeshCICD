# 🚀 Enterprise DataOps Pipeline with SQLMesh, DuckDB & GitHub Actions

Este repositorio implementa una arquitectura moderna de **DataOps** de nivel empresarial. Utiliza **SQLMesh** como motor de transformación y virtualización de esquemas, **DuckDB** como motor analítico de alto rendimiento y **GitHub Actions** para la orquestación y despliegue continuo (CI/CD) con separación de entornos e inspección humana en el ciclo de vida de los datos (*Human-in-the-loop*).

---

## 🏛️ Arquitectura del Sistema

```text
                                  +-----------------------+
                                  |    Fuentes Raw (CSV)  |
                                  +-----------+-----------+
                                              |
                                              v
                                  +-----------------------+
                                  |   stg_transactions    |  (Capa Staging)
                                  +-----------+-----------+
                                              |
                                              v
                                  +-----------------------+
                                  |   core_transactions   |  (Capa Intermedia / Core)
                                  +-----------+-----------+
                                              |
                                              v
                                  +-----------------------+
                                  |      daily_sales      |  (Capa de Negocio / Marts)
                                  +-----------------------+
```

* **DuckDB:** Utilizado como motor de base de datos OLAP embebido. Permite iteración ultra-rápida y validación local de modelos sin costos de infraestructura cloud en fases tempranas.
* **SQLMesh:** Framework de modelado que garantiza la corrección temporal de datos, gestión automática de backfills, tests unitarios declarativos y *Virtual Virtualization* para promociones de código libres de riesgo.

---

## 🔄 Arquitectura de CI/CD y Gobierno de Entornos

Este proyecto implementa un flujo **Trunk-Based Development** asistido por la capacidad de *Virtual Virtualization* de SQLMesh. Los cambios de código se validan en entornos efímeros antes de ser promocionados secuencialmente a través de los entornos de datos **DEV**, **UAT** y **PROD**.

### 📊 Matriz de Entornos y Gobernanza

| Entorno | Disparador (*Trigger*) | Evento GitHub | Comportamiento SQLMesh | Puerta de Enlace (*Gate*) |
| :--- | :--- | :--- | :--- | :--- |
| **CI (PR Validation)** | Apertura / Update de PR | `pull_request` | `sqlmesh plan pr_<numero>` | **Automático** (Unit Tests + Esquema Aislado) |
| **DEV** | Fusionar a `main` | `push` a `main` | `sqlmesh plan dev --auto-apply` | **Automático** (CD Directo) |
| **UAT (Staging)** | Éxito en DEV | `needs: deploy-dev` | `sqlmesh plan uat --auto-apply` | **Aprobación Manual** (`uat` Environment) |
| **PROD (Production)**| Éxito en UAT | `needs: deploy-uat` | `sqlmesh plan prod --auto-apply` | **Aprobación Manual** (`production` Environment) |

---

### 🛠️ Flujo de Promoción del Código

```text
[ Feature Branch ]
       │
       ▼ (Abre Pull Request)
┌──────────────┐
│  CI Pipeline │ ──► Ejecuta Tests Unitarios + Crea entorno aislado `pr_<numero>`
└──────────────┘
       │
       ▼ ( Merge a 'main' )
┌──────────────┐
│   CD - DEV   │ ──► Aplica `sqlmesh plan dev --auto-apply` (Automático)
└──────────────┘
       │
       ▼ ( Pasa validaciones en DEV )
┌──────────────┐
│   CD - UAT   │ ──► Requiere aprobación manual en GitHub Environment `uat`
└──────────────┘     Ejecuta `sqlmesh plan uat --auto-apply`
       │
       ▼ ( Firma de aprobación de QA / Data Product Owner )
┌──────────────┐
│  CD - PROD   │ ──► Requiere aprobación manual en GitHub Environment `production`
└──────────────┘     Ejecuta `sqlmesh plan prod --auto-apply`
```

---

## 🧪 Calidad de Datos y Tests Unitarios

Los tests están definidos de forma declarativa bajo la carpeta `tests/`. Garantizan que las transformaciones complejas y agregaciones respeten la lógica de negocio antes de tocar cualquier entorno de base de datos.

### Ejecución de Tests
```bash
# Ejecutar la suite completa de tests unitarios
sqlmesh test
```

---

## 🚀 Guía de Inicio Rápido (Desarrollo Local)

### 1. Prerrequisitos
* Python 3.10 o superior
* Git

### 2. Instalación del Entorno
```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/tu-repositorio.git
cd tu-repositorio

# Crear y activar entorno virtual
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt

# Asegurar la creación del directorio para la base de datos DuckDB
mkdir -p db
```

### 3. Flujo de Trabajo Local con SQLMesh
```bash
# 1. Comprobar sintaxis y tests
sqlmesh test

# 2. Generar y evaluar un plan de cambios local en ambiente 'dev'
sqlmesh plan dev

# 3. Aplicar cambios a producción local (solo tras validar)
sqlmesh plan
```

---

## 📁 Estructura del Repositorio

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml              # Pipeline de CI (Ejecución en PRs)
│       └── cd.yml              # Pipeline de CD (Promoción DEV -> UAT -> PROD)
├── config.yaml                 # Configuración del proyecto SQLMesh y conexiones
├── audits/                     # Filtros de control para pasar de Staging a Silver y Gold
├── db/                         # Directorio local para almacenamiento de DuckDB
├── docs/                       # Directorio local para documentacion
├────── readme.md
├────── Checklist.md
├── models/                     # Definición de modelos SQL (Staging, Core, Marts)
│   ├── core/                   # Core Models
│   ├── marts/                  # Marts Models
│   └── staging/                # Staging Models
├── sources                     # Archivos CSV para carga de datos iniciales
│   └── transactions/           # Archivos relativos a transactions
├── tests/                      # Suite de pruebas unitarias en YAML
├── .gitignore
└── requirements.txt            # Dependencias de Python (sqlmesh, duckdb, etc.)