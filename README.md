# Enterprise SQL Data Warehouse Project

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion%20(Bronze%20%7C%20Silver%20%7C%20Gold)-orange?style=for-the-badge)](#data-architecture)
[![Model](https://img.shields.io/badge/Data%20Model-Star%20Schema-green?style=for-the-badge)](#data-modeling--gold-layer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

An end-to-end modern Data Warehouse and Business Intelligence engineering solution built on **PostgreSQL**. This project consolidates raw transactional and operational data from disparate enterprise source systems (**CRM** and **ERP**), processes it through a multi-tier **Medallion Architecture (Bronze &rarr; Silver &rarr; Gold)**, and delivers an analytics-ready **Star Schema** optimized for analytical reporting, customer intelligence, and executive decision-making.

---

## 📑 Table of Contents

- [Executive Summary & Objectives](#executive-summary--objectives)
- [Data Architecture](#data-architecture)
  - [The Medallion Architecture](#the-medallion-architecture)
  - [Architecture & Data Flow Diagrams](#architecture--data-flow-diagrams)
- [Source Systems & Datasets](#source-systems--datasets)
- [Layer-by-Layer Implementation](#layer-by-layer-implementation)
  - [1. Database Initialization](#1-database-initialization)
  - [2. Bronze Layer (Raw Ingestion)](#2-bronze-layer-raw-ingestion)
  - [3. Silver Layer (Cleansing & Transformation)](#3-silver-layer-cleansing--transformation)
  - [4. Gold Layer (Dimensional Modeling & Star Schema)](#4-gold-layer-dimensional-modeling--star-schema)
- [Data Quality & Automated Testing](#data-quality--automated-testing)
- [Data Catalog & Schema Reference](#data-catalog--schema-reference)
- [Repository Structure](#repository-structure)
- [Setup & Deployment Guide](#setup--deployment-guide)
- [Sample Analytical Queries](#sample-analytical-queries)
- [Design Standards & Naming Conventions](#design-standards--naming-conventions)
- [Author & License](#author--license)

---

## Executive Summary & Objectives

Modern enterprises accumulate data across fragmented operational systems. In this project, customer, sales, product, and geographic information resides across separate **Customer Relationship Management (CRM)** and **Enterprise Resource Planning (ERP)** platforms with conflicting formats, duplicate entries, missing attributes, and inconsistent keys.

### Core Objectives:
1. **Source Integration:** Seamlessly ingest and consolidate disparate ERP and CRM data sources into a centralized repository.
2. **Data Cleansing & Standardization:** Rectify dirty data, resolve discrepancies (e.g., gender, marital status, country aliases), remove duplicates, and impute missing costs and dates.
3. **Data Modeling (Star Schema):** Transform cleaned data into high-performance dimensional models (Fact and Dimension views) with surrogate keys.
4. **Data Quality & Auditability:** Enforce stringent validation checks at every boundary with metadata tracking (`dwh_create_at`) and performance metrics.
5. **Business Intelligence Enablement:** Empower analysts and stakeholders with instant SQL insights into customer behavior, sales performance, and product trends.

---

## Data Architecture

### The Medallion Architecture

This data warehouse follows the industry-standard **Medallion Architecture**, establishing three clear layers of data refinement:

```
┌────────────────────────┐      ┌────────────────────────┐      ┌────────────────────────┐
│      BRONZE LAYER      │      │      SILVER LAYER      │      │       GOLD LAYER       │
│      (Raw Staging)     │ ───► │   (Cleaned & Enriched) │ ───► │  (Star Schema / BI)    │
│                        │      │                        │      │                        │
│ • Full historical load │      │ • Deduplication        │      │ • Dim Customers        │
│ • Direct CSV COPY      │      │ • Type casting         │      │ • Dim Products         │
│ • 1:1 Source Schema    │      │ • Null handling        │      │ • Fact Sales           │
│ • Minimal alteration   │      │ • SCD Type 2 logic     │      │ • Business aggregates  │
└────────────────────────┘      └────────────────────────┘      └────────────────────────┘
```

1. **Bronze Layer (`bronze` schema):**
   - Ingests raw source data from CSV flat files directly into staging tables without schema modification.
   - Fast, automated loading using stored procedure `bronze.load_dataset()`.
2. **Silver Layer (`silver` schema):**
   - Performs data scrubbing, standardization, deduplication via window functions (`ROW_NUMBER()`), key parsing, and business logic application.
   - Includes metadata tracking columns (`dwh_create_at`).
   - Orchestrated via stored procedure `silver.load_dataset()`.
3. **Gold Layer (`gold` schema):**
   - Business-ready dimensional model organized in a **Star Schema**.
   - Generates surrogate keys (`customer_key`, `product_key`) and establishes foreign key relationships for seamless reporting and BI dashboards.

### Architecture & Data Flow Diagrams

#### System Data Architecture
![Data Architecture](documents/Data%20architecture.jpg)

#### End-to-End Data Flow
![Data Flow Diagram](documents/Data%20Flow%20Digrma.png)

#### Data Integration Workflow
![Data Integration](documents/data%20integration.png)

#### Star Schema Data Model
![Data Model](documents/data%20model.png)

---

## Source Systems & Datasets

Data is sourced from two enterprise platforms located in the `datasets/` directory:

| Source System | File Name | Target Bronze Table | Description |
| :--- | :--- | :--- | :--- |
| **CRM** | `cust_info.csv` | `bronze.crm_cust_info` | Customer master details (names, marital status, gender, creation date). |
| **CRM** | `prd_info.csv` | `bronze.crm_prd_info` | Product catalog (composite keys, product names, costs, product lines, start/end dates). |
| **CRM** | `sales_details.csv` | `bronze.crm_sales_details` | Transactional sales orders (order number, product key, customer ID, dates, amounts, quantities, prices). |
| **ERP** | `CUST_AZ12.csv` | `bronze.erp_cust_az12` | Demographic supplementary data (customer birthdates and gender). |
| **ERP** | `LOC_A101.csv` | `bronze.erp_loc_a101` | Customer location mapping (customer IDs with hyphens, country codes). |
| **ERP** | `PX_CAT_G1V2.csv` | `bronze.erp_px_cat_g1v2` | Product category and maintenance classifications. |

---

## Layer-by-Layer Implementation

### 1. Database Initialization
File: [`scripts/init_database.sql`](scripts/init_database.sql)

Initializes the `DataWarehouse` database and sets up isolated schemas representing the three architectural tiers:
```sql
CREATE DATABASE "DataWarehouse";

-- Medallion Schemas
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
```

---

### 2. Bronze Layer (Raw Ingestion)
Files:
- Table DDL: [`scripts/bronze/bronze_tables.sql`](scripts/bronze/bronze_tables.sql)
- Ingestion Procedure: [`scripts/bronze/sp_load.sql`](scripts/bronze/sp_load.sql)

The Bronze layer creates exact mirrors of source systems and utilizes PostgreSQL high-speed `COPY` commands wrapped inside a stored procedure:
```sql
CREATE OR REPLACE PROCEDURE bronze.load_dataset()
...
```
**Key Highlights:**
- **Idempotency:** Truncates staging tables before loading to prevent duplicate accumulation during pipeline re-runs.
- **Observability:** Tracks and prints individual table load durations, execution timestamps, and loaded row counts to the console.

---

### 3. Silver Layer (Cleansing & Transformation)
Files:
- Table DDL: [`scripts/silver/silver_tables.sql`](scripts/silver/silver_tables.sql)
- ETL Stored Procedure: [`scripts/silver/sp_load_silver.sql`](scripts/silver/sp_load_silver.sql)

The Silver pipeline executes data quality corrections, normalization, and business transformations:

#### A. Deduplication & Data Quality
- **Customer Deduplication:** Retains only the most up-to-date customer record based on the latest creation date:
  ```sql
  ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_rnk
  WHERE flag_rnk = 1
  ```
- **Whitespace Sanitation:** Removes leading and trailing whitespaces across all text attributes (`TRIM(cst_firstname)`, `TRIM(cst_lastname)`).

#### B. Standardization & Value Harmonization
- **Marital Status & Gender:** Standardizes abbreviations (`M` &rarr; `Married`/`Male`, `S` &rarr; `Single`, `F` &rarr; `Female`, missing &rarr; `n/a`).
- **Country Harmonization:** Unifies diverse country spellings (`US`, `USA`, `UNITED STATES` &rarr; `United States`, `DE` &rarr; `Germany`).

#### C. Key Splitting & Date Engineering
- **Composite Key Splitting:** Splits CRM product keys like `CO-MF-FR-M94B-46` into `cat_id` (`CO_MF`) and clean `prd_key` (`FR-M94B-46`).
- **SCD Type 2 Effective End Date Calculation:** Uses window navigation to set a product's end date to one day prior to the next product version start date:
  ```sql
  (LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1)::DATE AS prd_end_dt
  ```
- **Integer to Date Conversion:** Converts raw integer dates (`YYYYMMDD` format) to SQL `DATE` types, catching and nullifying malformed values (`0` or length $\neq$ 8).

#### D. Metric Validation & Cross-System Cleanliness
- **Sales Discrepancy Correction:** Reconciles invalid sales amounts and unit prices where $\text{sales} \neq \text{quantity} \times \text{price}$.
- **Customer ID Alignment:** Strips invalid ERP prefixes (`NAS101` &rarr; `101`) and cleanses customer location IDs by removing hyphens (`-`).

---

### 4. Gold Layer (Dimensional Modeling & Star Schema)
File: [`scripts/gold/gold_ddl.sql`](scripts/gold/gold_ddl.sql)

The Gold layer transforms cleansed Silver data into an analytical **Star Schema** comprised of business-ready SQL views.

```
       ┌────────────────────────┐
       │   gold.dim_customers   │
       ├────────────────────────┤
       │ PK  customer_key       │◄────────┐
       │     customer_id        │         │
       │     customer_number    │         │
       │     first_name         │         │
       │     last_name          │         │
       │     country            │         │
       │     gender             │         │
       │     birthdate          │         │
       └────────────────────────┘         │
                                          │ 1:N
                               ┌──────────┴─────────────┐
                               │    gold.fact_sales     │
                               ├────────────────────────┤
                               │     order_number       │
                               │ FK  customer_key       │
                               │ FK  product_key        │
                               │     order_date         │
                               │     shipping_date      │
                               │     due_date           │
                               │     sales_amount       │
                               │     quantity           │
                               │     price              │
                               └──────────┬─────────────┘
                                          │ 1:N
       ┌────────────────────────┐         │
       │    gold.dim_products   │         │
       ├────────────────────────┤         │
       │ PK  product_key        │◄────────┘
       │     product_id         │
       │     product_number     │
       │     product_name       │
       │     category           │
       │     subcategory        │
       │     maintenance        │
       │     product_cost       │
       │     product_line       │
       └────────────────────────┘
```

#### Views Overview:
1. **`gold.dim_customers`**:
   - Integrates CRM customer demographic details with ERP birthdate (`erp_cust_az12`) and country (`erp_loc_a101`).
   - Resolves attribute priority: CRM gender is primary; ERP gender acts as fallback.
   - Generates surrogate key `customer_key` using `ROW_NUMBER()`.
2. **`gold.dim_products`**:
   - Merges CRM product data with ERP category classifications (`erp_px_cat_g1v2`).
   - Filters out expired/historical versions (`prd_end_dt IS NULL`) to represent only currently active products.
   - Generates surrogate key `product_key`.
3. **`gold.fact_sales`**:
   - Central sales transactions linked via foreign keys to `dim_customers` (`customer_key`) and `dim_products` (`product_key`).
   - Exposes business measures: `sales_amount`, `quantity`, and unit `price`.

---

## Data Quality & Automated Testing

To ensure 100% data reliability, the project includes structured test suites executed at each stage:

### 1. Silver Layer Validation (`tests/quality_check_silver.sql`)
- [x] **Primary Key & Uniqueness:** Verifies zero nulls and no duplicate customer IDs or product keys.
- [x] **Whitespace Invariant Check:** Confirms no lingering leading or trailing spaces.
- [x] **Domain Value Integrity:** Validates that categorical attributes (`gender`, `marital_status`, `product_line`, `country`) conform strictly to authorized domains.
- [x] **Temporal Validation:** Checks that birthdates fall between `1925-01-01` and `CURRENT_DATE`, and that order dates adhere to realistic calendar windows.
- [x] **Calculated Metric Integrity:** Asserts that $\text{sales} = \text{quantity} \times \text{price}$ and that quantities/prices are positive.

### 2. Gold Layer Validation (`tests/quality_check_gold.sql`)
- [x] **Cross-System Conflict Detection:** Validates conflict-resolution logic between CRM and ERP customer attributes.
- [x] **Dimension Duplicate Checks:** Asserts that surrogate keys (`customer_key`, `product_key`) are strictly unique across all dimensional records.
- [x] **Referential Integrity:** Performs integrity audits verifying that foreign keys in `gold.fact_sales` join cleanly to corresponding dimension views without orphan records.

---

## Data Catalog & Schema Reference

Detailed documentation is available in [`documents/Data catalog.md`](documents/Data%20catalog.md).

### 1. `gold.dim_customers`
| Column Name | Data Type | Key Type | Description |
| :--- | :--- | :--- | :--- |
| `customer_key` | `INT` | Primary Key | Surrogate key generated via `ROW_NUMBER()`. |
| `customer_id` | `INT` | Natural Key | Unique numerical customer identifier from CRM. |
| `customer_number` | `NVARCHAR(50)`| Alternate Key | Alphanumeric business customer code. |
| `first_name` | `NVARCHAR(50)`| Attribute | Standardized first name. |
| `last_name` | `NVARCHAR(50)`| Attribute | Standardized last name. |
| `country` | `NVARCHAR(50)`| Attribute | Harmonized country name. |
| `marital_status` | `NVARCHAR(50)`| Attribute | Standardized marital status (`Married`, `Single`, `n/a`). |
| `gender` | `NVARCHAR(50)`| Attribute | Resolved gender (`Male`, `Female`, `n/a`). |
| `birthdate` | `DATE` | Attribute | Date of birth ($1925 \le \text{date} \le \text{today}$). |
| `create_date` | `DATE` | Audit | Account creation date. |

### 2. `gold.dim_products`
| Column Name | Data Type | Key Type | Description |
| :--- | :--- | :--- | :--- |
| `product_key` | `INT` | Primary Key | Surrogate key generated via `ROW_NUMBER()`. |
| `product_id` | `INT` | Natural Key | Product internal identifier. |
| `product_number` | `NVARCHAR(50)`| Alternate Key | Normalized product code. |
| `product_name` | `NVARCHAR(50)`| Attribute | Full descriptive product name. |
| `category_id` | `NVARCHAR(50)`| Foreign Key | Category grouping code (`CO_MF`, etc.). |
| `category` | `NVARCHAR(50)`| Attribute | High-level category (Bikes, Components, etc.). |
| `subcategory` | `NVARCHAR(50)`| Attribute | Sub-category classification. |
| `maintenance` | `NVARCHAR(50)`| Attribute | Maintenance eligibility flag (`Yes`, `No`). |
| `product_cost` | `INT` | Metric | Product cost base. |
| `product_line` | `NVARCHAR(50)`| Attribute | Product line (Road, Mountain, Touring, etc.). |
| `start_date` | `DATE` | Attribute | Effective catalog start date. |

### 3. `gold.fact_sales`
| Column Name | Data Type | Key Type | Description |
| :--- | :--- | :--- | :--- |
| `order_number` | `NVARCHAR(50)`| Degenerate Key| Unique sales order identifier. |
| `product_key` | `INT` | Foreign Key | References `gold.dim_products.product_key`. |
| `customer_key` | `INT` | Foreign Key | References `gold.dim_customers.customer_key`. |
| `order_date` | `DATE` | Dimension Key | Date the sales order was placed. |
| `shipping_date` | `DATE` | Dimension Key | Date the order shipped. |
| `due_date` | `DATE` | Dimension Key | Payment due date. |
| `sales_amount` | `INT` | Measure | Total order line sales amount. |
| `quantity` | `INT` | Measure | Number of items purchased. |
| `price` | `INT` | Measure | Unit sale price. |

---

## Repository Structure

```plaintext
SQL-data-warehouse-project/
├── datasets/                                 # Raw source data CSV files
│   ├── source_crm/                           # Customer Relationship Management source
│   │   ├── cust_info.csv                     # Customer demographics and records
│   │   ├── prd_info.csv                      # Product catalog details
│   │   └── sales_details.csv                 # Raw sales transactions
│   └── source_erp/                           # Enterprise Resource Planning source
│       ├── CUST_AZ12.csv                     # Customer birthdate and gender data
│       ├── LOC_A101.csv                      # Customer country and location mapping
│       └── PX_CAT_G1V2.csv                   # Product category details
├── documents/                                # Architectural documentation & specs
│   ├── Data architecture.jpg                 # System architecture diagram
│   ├── Data Flow Digrma.png                  # End-to-end data pipeline flow diagram
│   ├── data integration.png                  # Integration workflow diagram
│   ├── data model.png                        # Dimensional Star Schema diagram
│   ├── Data catalog.md                       # Comprehensive data dictionary
│   ├── naming_conventions.md                 # Project naming & SQL design standards
│   ├── Project_Requirements.pdf              # One-page executive requirements PDF
│   └── requirements.md                       # Detailed engineering requirements
├── scripts/                                  # Database build & pipeline scripts
│   ├── init_database.sql                     # Database & schema setup script
│   ├── bronze/                               # Bronze layer DDL & ingestion
│   │   ├── bronze_tables.sql                 # Staging tables DDL
│   │   └── sp_load.sql                       # Bronze COPY ETL stored procedure
│   ├── silver/                               # Silver layer DDL & transformation
│   │   ├── silver_tables.sql                 # Cleaned tables DDL
│   │   └── sp_load_silver.sql                # Silver transformation stored procedure
│   └── gold/                                 # Gold layer DDL & views
│       └── gold_ddl.sql                      # Dimensional Star Schema views
├── tests/                                    # Automated Data Quality test suites
│   ├── quality_check_silver.sql              # Validation tests for Silver layer
│   └── quality_check_gold.sql                # Integration & integrity tests for Gold layer
├── LICENSE                                   # MIT License
└── README.md                                 # Project documentation
```

---

## Setup & Deployment Guide

Follow these steps to deploy the Data Warehouse locally using **PostgreSQL** and **pgAdmin** / **psql**:

### Prerequisites
- [PostgreSQL 14+](https://www.postgresql.org/download/) installed and running.
- [pgAdmin 4](https://www.pgadmin.org/) or terminal access via `psql`.
- Git installed.

### Step 1: Clone the Repository
```bash
git clone https://github.com/singhkrish2607-sudo/SQL-data-warehouse-project.git
cd SQL-data-warehouse-project
```

### Step 2: Initialize Database and Schemas
Run [`scripts/init_database.sql`](scripts/init_database.sql) to create the database and required schemas (`bronze`, `silver`, `gold`):
```sql
\i scripts/init_database.sql
```
*(Connect to the newly created `DataWarehouse` database before running subsequent scripts.)*

### Step 3: Build & Load Bronze Layer
1. Execute table definitions in [`scripts/bronze/bronze_tables.sql`](scripts/bronze/bronze_tables.sql).
2. Update the absolute file paths in [`scripts/bronze/sp_load.sql`](scripts/bronze/sp_load.sql) pointing to your local `datasets/` path.
3. Create the procedure and trigger ingestion:
   ```sql
   \i scripts/bronze/sp_load.sql
   CALL bronze.load_dataset();
   ```

### Step 4: Build & Load Silver Layer
1. Execute table definitions in [`scripts/silver/silver_tables.sql`](scripts/silver/silver_tables.sql).
2. Execute the Silver transformation stored procedure in [`scripts/silver/sp_load_silver.sql`](scripts/silver/sp_load_silver.sql):
   ```sql
   \i scripts/silver/sp_load_silver.sql
   CALL silver.load_dataset();
   ```

### Step 5: Build Gold Layer Analytical Views
Deploy the dimension and fact views in [`scripts/gold/gold_ddl.sql`](scripts/gold/gold_ddl.sql):
```sql
\i scripts/gold/gold_ddl.sql
```

### Step 6: Run Quality & Verification Suites
Execute the test suites to confirm that data quality rules, integrity checks, and row counts match specifications:
```sql
\i tests/quality_check_silver.sql
\i tests/quality_check_gold.sql
```



## Design Standards & Naming Conventions

The repository adheres strictly to the architectural standards documented in [`documents/naming_conventions.md`](documents/naming_conventions.md):

- **General Formatting:** `snake_case` using lowercase English letters and underscores.
- **Bronze & Silver Tables:** Prefixed by source system name: `<source>_<entity>` (e.g., `crm_cust_info`, `erp_loc_a101`).
- **Gold Layer Views:** Prefixed by structural role:
  - `dim_<entity>` for dimension tables (e.g., `dim_customers`, `dim_products`).
  - `fact_<entity>` for transaction tables (e.g., `fact_sales`).
- **Keys:**
  - Surrogate primary keys end with `_key` (e.g., `customer_key`, `product_key`).
  - Business identifiers keep source name or end in `_id` / `_number`.
- **Audit Columns:** Technical system metadata columns are prefixed with `dwh_` (e.g., `dwh_create_at`).
- **Stored Procedures:** Standardized as `load_<layer>()` (e.g., `load_dataset()`).

---

## Author & License

- **Developer:** [Krish Singh](https://github.com/singhkrish2607-sudo)
- **Repository:** [SQL-data-warehouse-project](https://github.com/singhkrish2607-sudo/SQL-data-warehouse-project)
- **License:** Released under the [MIT License](LICENSE).
