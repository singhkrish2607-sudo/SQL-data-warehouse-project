
/*
===============================================================================
Project      : Data Warehouse
Script       : Create Bronze Layer Tables
Database     : DataWarehouse
Schema       : bronze
Platform     : PostgreSQL
Architecture : Medallion Architecture

PURPOSE:
    Create the Bronze Layer tables to store raw data imported from
    the CRM and ERP source systems.

SOURCE SYSTEMS:
    1. CRM (Customer Relationship Management)
    2. ERP (Enterprise Resource Planning)

WARNING:
    DROP TABLE IF EXISTS permanently removes the existing table
    and all its data before recreating it.

    Make sure you have a backup if the existing data is important.

IMPORTANT:
    These tables are designed to hold raw source data.
    Data cleaning, standardization, and transformation will be
    performed in the Silver Layer.
===============================================================================
*/


-- =============================================================================
-- SECTION 1: CRM SOURCE TABLES
-- =============================================================================
-- PURPOSE:
--     Store raw data extracted from the CRM source system.
--     These tables contain customer, product, and sales information.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TABLE 1: CRM CUSTOMER INFORMATION
-- Source File : cust_info.csv
-- Purpose     : Store raw customer details.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id              INTEGER,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(100),
    cst_lastname        VARCHAR(100),
    cst_marital_status  VARCHAR(5),
    cst_gndr            VARCHAR(5),
    cst_create_date     DATE
);


-- -----------------------------------------------------------------------------
-- TABLE 2: CRM PRODUCT INFORMATION
-- Source File : prd_info.csv
-- Purpose     : Store raw product details, costs, and product categories.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id          INTEGER,
    prd_key         VARCHAR(50),
    prd_nm          VARCHAR(100),
    prd_cost        INTEGER,
    prd_line        VARCHAR(5),
    prd_start_dt    DATE,
    prd_end_dt      DATE
);


-- -----------------------------------------------------------------------------
-- TABLE 3: CRM SALES DETAILS
-- Source File : sales_details.csv
-- Purpose     : Store raw sales transaction details, including order,
--               customer, product, shipping, and revenue information.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     VARCHAR(50),
    sls_prd_key     VARCHAR(50),
    sls_cust_id     INTEGER,
    sls_order_dt    INTEGER,
    sls_ship_dt     INTEGER,
    sls_due_dt      INTEGER,
    sls_sales       INTEGER,
    sls_quantity    INTEGER,
    sls_price       INTEGER
);


-- =============================================================================
-- SECTION 2: ERP SOURCE TABLES
-- =============================================================================
-- PURPOSE:
--     Store raw data extracted from the ERP source system.
--     These tables contain customer, location, and product category details.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TABLE 4: ERP CUSTOMER INFORMATION
-- Source File : CUST_AZ12.csv
-- Purpose     : Store additional customer information, including birthdate
--               and gender, from the ERP source system.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid     VARCHAR(50),
    bdate   DATE,
    gen     VARCHAR(50)
);


-- -----------------------------------------------------------------------------
-- TABLE 5: ERP CUSTOMER LOCATION
-- Source File : LOC_A101.csv
-- Purpose     : Store customer location and country information.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
    cid     VARCHAR(50),
    cntry   VARCHAR(50)
);


-- -----------------------------------------------------------------------------
-- TABLE 6: ERP PRODUCT CATEGORY
-- Source File : PX_CAT_G1V2.csv
-- Purpose     : Store product category, subcategory, and maintenance details.
-- -----------------------------------------------------------------------------

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id              VARCHAR(50),
    cat             VARCHAR(50),
    subcat          VARCHAR(50),
    maintenance     VARCHAR(10)
);


-- =============================================================================
-- END OF BRONZE LAYER TABLE CREATION
-- =============================================================================
-- SUMMARY:
--
-- CRM TABLES:
--     1. bronze.crm_cust_info
--     2. bronze.crm_prd_info
--     3. bronze.crm_sales_details
--
-- ERP TABLES:
--     4. bronze.erp_cust_az12
--     5. bronze.erp_loc_a101
--     6. bronze.erp_px_cat_g1v2
--
-- NEXT STEPS:
--     1. Import raw CSV datasets into the Bronze tables.
--     2. Validate successful data loading.
--     3. Check record counts and source data consistency.
--     4. Begin data cleaning and transformation in the Silver Layer.
--
-- =============================================================================
