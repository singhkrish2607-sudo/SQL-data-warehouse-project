
-- ============================================================
-- SILVER LAYER: DATA QUALITY & TRANSFORMATION TESTING
-- ============================================================
-- Project  : Data Warehouse
-- Layer    : Silver
-- Purpose  : Validate data quality, identify inconsistencies,
--            and test transformation logic before loading data
--            into the Silver Layer.
-- Database : PostgreSQL
-- ============================================================


-- ============================================================
-- SECTION 1: CRM CUSTOMER INFORMATION
-- Source Table: bronze.crm_cust_info
-- Target Table: silver.crm_cust_info
-- ============================================================


-- ------------------------------------------------------------
-- TEST 1: Check for NULL and Duplicate Customer IDs
-- Expectation: No Results
-- ------------------------------------------------------------

SELECT
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;


-- ------------------------------------------------------------
-- TEST 2: Check for Unwanted Spaces in Customer Keys
-- Expectation: No Results
-- ------------------------------------------------------------

SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key <> TRIM(cst_key);


-- ------------------------------------------------------------
-- TEST 3: Check Marital Status Standardization
-- Expectation: Only Married, Single, or n/a
-- ------------------------------------------------------------

SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;


-- ------------------------------------------------------------
-- TEST 4: Check Gender Standardization
-- Expectation: Only Male, Female, or n/a
-- ------------------------------------------------------------

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;


-- ============================================================
-- SECTION 2: CRM PRODUCT INFORMATION
-- Source Table: bronze.crm_prd_info
-- Target Table: silver.crm_prd_info
-- ============================================================


-- ------------------------------------------------------------
-- TEST 1: Explore Raw Product Information
-- ------------------------------------------------------------

SELECT *
FROM bronze.crm_prd_info;


-- ------------------------------------------------------------
-- TEST 2: Check for NULL and Duplicate Product Keys
-- Expectation: No Results
-- ------------------------------------------------------------

SELECT
    prd_key,
    COUNT(*) AS duplicate_count
FROM bronze.crm_prd_info
GROUP BY prd_key
HAVING COUNT(*) > 1
    OR prd_key IS NULL
ORDER BY duplicate_count DESC;


-- ------------------------------------------------------------
-- TEST 3: Investigate a Specific Product Key
-- Purpose: Understand product key structure
-- ------------------------------------------------------------

SELECT *
FROM bronze.crm_prd_info
WHERE prd_key = 'CO-MF-FR-M94B-46';


-- ------------------------------------------------------------
-- TEST 4: Check Product Cost
-- Purpose: Identify NULL or invalid product costs
-- Expectation: Transformed cost should not be negative
-- ------------------------------------------------------------

SELECT
    prd_id,
    prd_key,

    -- Extract category ID
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

    -- Extract product key
    SUBSTRING(prd_key, 7) AS product_key,

    prd_nm,

    -- Replace missing costs with zero
    COALESCE(prd_cost, 0) AS prd_cost,

    prd_line,
    prd_start_dt,
    prd_end_dt

FROM bronze.crm_prd_info
WHERE prd_cost <= 0
    OR prd_cost IS NULL;


-- ------------------------------------------------------------
-- TEST 5: Validate Product Start and End Dates
-- Purpose: Calculate product end dates using LEAD()
-- ------------------------------------------------------------

SELECT
    prd_id,
    prd_key,

    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7) AS product_key,

    prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost,
    prd_line,
    prd_start_dt,

    -- Calculate end date as one day before the next start date
    (
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) - 1
    )::DATE AS prd_end_dt_test

FROM bronze.crm_prd_info
ORDER BY prd_id;


-- ============================================================
-- SECTION 3: CRM SALES DETAILS
-- Source Table: bronze.crm_sales_details
-- Target Table: silver.crm_sales_details
-- ============================================================


-- ------------------------------------------------------------
-- TEST 1: Explore Raw Sales Information
-- ------------------------------------------------------------

SELECT *
FROM bronze.crm_sales_details;


-- ------------------------------------------------------------
-- TEST 2: Check for NULL and Duplicate Sales Order Numbers
-- Expectation: No Results
-- ------------------------------------------------------------

SELECT
    sls_ord_num,
    COUNT(*) AS duplicate_count
FROM bronze.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*) > 1
    OR sls_ord_num IS NULL
ORDER BY duplicate_count DESC;


-- ------------------------------------------------------------
-- TEST 3: Investigate a Specific Sales Order
-- ------------------------------------------------------------

SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num = 'SO70714';


-- ------------------------------------------------------------
-- TEST 4: Review Sales Columns
-- ------------------------------------------------------------

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details;


-- ------------------------------------------------------------
-- TEST 5: Validate Product Keys
-- Purpose: Check product keys used in sales transactions
-- ------------------------------------------------------------

SELECT DISTINCT
    sls_prd_key
FROM bronze.crm_sales_details;


-- ------------------------------------------------------------
-- TEST 6: Validate Order Dates
-- Purpose: Identify zero, malformed, or out-of-range dates
-- ------------------------------------------------------------

SELECT
    sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt = 0
    OR LENGTH(sls_order_dt::TEXT) <> 8
    OR sls_order_dt > TO_CHAR(CURRENT_DATE, 'YYYYMMDD')::INTEGER
    OR sls_order_dt < 20100101;


-- ------------------------------------------------------------
-- TEST 7: Validate Shipping Dates
-- ------------------------------------------------------------

SELECT
    sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt = 0
    OR LENGTH(sls_ship_dt::TEXT) <> 8
    OR sls_ship_dt > TO_CHAR(CURRENT_DATE, 'YYYYMMDD')::INTEGER
    OR sls_ship_dt < 20100101;


-- ------------------------------------------------------------
-- TEST 8: Validate Due Dates
-- ------------------------------------------------------------

SELECT
    sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt = 0
    OR LENGTH(sls_due_dt::TEXT) <> 8
    OR sls_due_dt > TO_CHAR(CURRENT_DATE, 'YYYYMMDD')::INTEGER
    OR sls_due_dt < 20100101;


-- ------------------------------------------------------------
-- TEST 9: Convert and Validate Sales Dates
-- Purpose:
--   1. Replace invalid date values with NULL.
--   2. Convert valid YYYYMMDD values into DATE format.
--   3. Identify incorrect date relationships.
-- ------------------------------------------------------------

WITH sales AS (
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        CASE
            WHEN sls_order_dt = 0
                OR LENGTH(sls_order_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END AS sls_order_dt,

        CASE
            WHEN sls_ship_dt = 0
                OR LENGTH(sls_ship_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END AS sls_ship_dt,

        CASE
            WHEN sls_due_dt = 0
                OR LENGTH(sls_due_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END AS sls_due_dt,

        sls_sales,
        sls_quantity,
        sls_price

    FROM bronze.crm_sales_details
)

SELECT
    sls_ord_num,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt
FROM sales
WHERE sls_order_dt > sls_ship_dt
    OR sls_order_dt > sls_due_dt;


-- ------------------------------------------------------------
-- TEST 10: Validate Sales, Quantity, and Price
-- Source: Silver CRM Sales Details
-- Expectation: No incorrect or missing calculations
-- ------------------------------------------------------------

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> (sls_quantity * sls_price)
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;


-- ============================================================
-- SECTION 4: ERP CUSTOMER INFORMATION
-- Source Table: bronze.erp_cust_az12
-- Target Table: silver.erp_cust_az12
-- ============================================================


-- ------------------------------------------------------------
-- TEST 1: Explore ERP Customer Information
-- ------------------------------------------------------------

SELECT
    cid,
    bdate,
    gen
FROM bronze.erp_cust_az12;


-- ------------------------------------------------------------
-- TEST 2: Validate ERP Customer IDs Against CRM
-- Purpose: Identify ERP customer IDs missing from CRM
-- ------------------------------------------------------------

WITH customer AS (
    SELECT
        cid,

        -- Remove NAS prefix
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
            ELSE cid
        END AS cid_t,

        bdate,
        gen

    FROM bronze.erp_cust_az12
)

SELECT
    e.cid,
    e.cid_t
FROM customer e
WHERE NOT EXISTS (
    SELECT 1
    FROM silver.crm_cust_info c
    WHERE c.cst_key = e.cid_t
);


-- ------------------------------------------------------------
-- TEST 3: Validate Birth Dates
-- Purpose:
--   1. Identify future birth dates.
--   2. Identify birth dates earlier than 1925.
-- Expectation: Invalid dates should be converted to NULL.
-- ------------------------------------------------------------

SELECT
    cid,
    bdate,

    CASE
        WHEN bdate > CURRENT_DATE
            OR bdate < DATE '1925-01-01'
            THEN NULL
        ELSE bdate
    END AS bdate_test,

    gen

FROM bronze.erp_cust_az12
WHERE bdate < DATE '1925-01-01'
    OR bdate > CURRENT_DATE
ORDER BY cid;


-- ------------------------------------------------------------
-- TEST 4: Check Distinct Gender Values
-- Purpose: Explore original gender values
-- ------------------------------------------------------------

SELECT DISTINCT
    gen
FROM bronze.erp_cust_az12;


-- ------------------------------------------------------------
-- TEST 5: Validate Gender Standardization
-- Expectation: Male, Female, or n/a
-- ------------------------------------------------------------

WITH gender AS (
    SELECT
        cid,
        gen,

        CASE
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                THEN 'Male'
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                THEN 'Female'
            ELSE 'n/a'
        END AS gen_test

    FROM bronze.erp_cust_az12
)

SELECT
    cid,
    gen,
    gen_test
FROM gender
WHERE gen_test = 'n/a';


-- ============================================================
-- SECTION 5: ERP CUSTOMER LOCATION
-- Source Table: bronze.erp_loc_a101
-- Target Table: silver.erp_loc_a101
-- ============================================================


-- ------------------------------------------------------------
-- TEST 1: Validate Customer IDs Against CRM
-- Purpose: Identify ERP customer IDs missing from CRM
-- ------------------------------------------------------------

WITH location AS (
    SELECT
        cid,
        REPLACE(cid, '-', '') AS cid_t,
        cntry
    FROM bronze.erp_loc_a101
)

SELECT
    l.cid,
    l.cid_t
FROM location l
WHERE NOT EXISTS (
    SELECT 1
    FROM silver.crm_cust_info c
    WHERE c.cst_key = l.cid_t
);


-- ------------------------------------------------------------
-- TEST 2: Standardize Country Names
-- Purpose: Handle missing values and normalize country codes
-- ------------------------------------------------------------

WITH country AS (
    SELECT
        cntry,

        CASE
            WHEN cntry IS NULL OR LENGTH(TRIM(cntry)) = 0
                THEN 'n/a'
            WHEN UPPER(TRIM(cntry)) IN (
                'US', 'USA', 'UNITED STATES'
            )
                THEN 'United States'
            WHEN UPPER(TRIM(cntry)) = 'DE'
                THEN 'Germany'
            ELSE TRIM(cntry)
        END AS cntry_test

    FROM bronze.erp_loc_a101
)

SELECT DISTINCT
    cntry_test
FROM country
ORDER BY cntry_test;


-- ============================================================
-- SECTION 6: ERP PRODUCT CATEGORY
-- Source Table: bronze.erp_px_cat_g1v2
-- Target Table: silver.erp_px_cat_g1v2
-- ============================================================


-- ------------------------------------------------------------
-- TEST 1: Explore Product Categories
-- ------------------------------------------------------------

SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;


-- ------------------------------------------------------------
-- TEST 2: Check for NULL and Duplicate Category IDs
-- Expectation: No Results
-- ------------------------------------------------------------

SELECT
    id,
    COUNT(*) AS duplicate_count
FROM bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1
    OR id IS NULL
ORDER BY duplicate_count DESC;


-- ------------------------------------------------------------
-- TEST 3: Check Distinct Product Subcategories
-- ------------------------------------------------------------

SELECT DISTINCT
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2
ORDER BY cat, subcat;


-- ============================================================
-- END: SILVER LAYER DATA QUALITY & TESTING
-- ============================================================

