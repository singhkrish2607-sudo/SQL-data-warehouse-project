# Silver Layer – Table Creation Script
-- ============================================================
-- Project  : Data Warehouse
-- Layer    : Silver
-- Purpose  : Create Silver Layer tables for transformed CRM
--            and ERP datasets.
-- Database : PostgreSQL
-- ============================================================

-- ============================================================
-- SECTION 1: CRM TABLES
-- ============================================================

-- ------------------------------------------------------------
-- 1. CRM Customer Information Table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info (
    cst_id              INTEGER,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(100),
    cst_lastname        VARCHAR(100),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE,

    -- Data Warehouse record creation timestamp
    dwh_create_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ------------------------------------------------------------
-- 2. CRM Product Information Table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id          INTEGER,
    prd_key         VARCHAR(50),
    prd_nm           VARCHAR(100),
    prd_cost         INTEGER,
    prd_line         VARCHAR(50),
    prd_start_dt     DATE,
    prd_end_dt       DATE,

    -- Data Warehouse record creation timestamp
    dwh_create_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ------------------------------------------------------------
-- 3. CRM Sales Details Table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     VARCHAR(50),
    sls_prd_key     VARCHAR(50),
    sls_cust_id     INTEGER,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INTEGER,
    sls_quantity    INTEGER,
    sls_price       INTEGER,

    -- Data Warehouse record creation timestamp
    dwh_create_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- SECTION 2: ERP TABLES
-- ============================================================

-- ------------------------------------------------------------
-- 4. ERP Customer Information Table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid             VARCHAR(50),
    bdate           DATE,
    gen             VARCHAR(50),

    -- Data Warehouse record creation timestamp
    dwh_create_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ------------------------------------------------------------
-- 5. ERP Customer Location Table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid             VARCHAR(50),
    cntry           VARCHAR(50),

    -- Data Warehouse record creation timestamp
    dwh_create_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ------------------------------------------------------------
-- 6. ERP Product Category Table
-- ------------------------------------------------------------

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              VARCHAR(50),
    cat             VARCHAR(50),
    subcat          VARCHAR(50),
    maintenance     VARCHAR(10),

    -- Data Warehouse record creation timestamp
    dwh_create_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- END: SILVER LAYER TABLE CREATION
-- ============================================================
