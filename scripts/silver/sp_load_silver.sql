-- ============================================================
-- Silver Layer Data Loading Procedure
-- ============================================================
-- Project  : Data Warehouse
-- Layer    : Silver
-- Purpose  : Clean, standardize, and transform raw CRM and ERP
--            data from the Bronze layer into Silver tables.
-- Database : PostgreSQL
-- ============================================================

CREATE OR REPLACE PROCEDURE silver.load_dataset()
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variables for measuring individual table load durations
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;

    -- Variables for measuring total procedure execution time
    p_start_time TIMESTAMPTZ;
    p_end_time TIMESTAMPTZ;

    -- Variable for storing the number of rows loaded into each table
    total_rows BIGINT;

BEGIN

    -- =========================================================
    -- START: SILVER LAYER DATA LOADING
    -- =========================================================

    -- Record the overall procedure start time
    p_start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '=================================================';
    RAISE NOTICE '             LOADING SILVER LAYER                ';
    RAISE NOTICE '=================================================';


    -- =========================================================
    -- SECTION 1: LOAD CRM TABLES
    -- =========================================================

    RAISE NOTICE '--------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '--------------------------------------------------';


    -- ---------------------------------------------------------
    -- 1. Load CRM Customer Information
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: silver.crm_cust_info';

    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE '>> Transforming and loading silver.crm_cust_info';

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,

        -- Remove leading and trailing spaces
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname) AS cst_lastname,

        -- Standardize marital status
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'M'
                THEN 'Married'
            WHEN UPPER(TRIM(cst_marital_status)) = 'S'
                THEN 'Single'
            ELSE 'n/a'
        END AS cst_marital_status,

        -- Standardize gender values
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'M'
                THEN 'Male'
            WHEN UPPER(TRIM(cst_gndr)) = 'F'
                THEN 'Female'
            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_rnk

        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t

    -- Keep only the most recent record for each customer
    WHERE flag_rnk = 1;


    -- Calculate table loading duration
    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);

    -- Count loaded records
    SELECT COUNT(*)
    INTO total_rows
    FROM silver.crm_cust_info;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';


    -- ---------------------------------------------------------
    -- 2. Load CRM Product Information
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: silver.crm_prd_info';

    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE '>> Transforming and loading silver.crm_prd_info';

    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,

        -- Extract and standardize category ID
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

        -- Extract product key
        SUBSTRING(prd_key, 7) AS prd_key,

        prd_nm,

        -- Replace missing product costs with zero
        COALESCE(prd_cost, 0) AS prd_cost,

        -- Standardize product line values
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,

        prd_start_dt,

        -- Calculate end date as one day before
        -- the next product start date
        (
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            ) - 1
        )::DATE AS prd_end_dt

    FROM bronze.crm_prd_info;


    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);

    SELECT COUNT(*)
    INTO total_rows
    FROM silver.crm_prd_info;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';


    -- ---------------------------------------------------------
    -- 3. Load CRM Sales Details
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: silver.crm_sales_details';

    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE '>> Transforming and loading silver.crm_sales_details';

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        -- Validate and convert order date
        CASE
            WHEN sls_order_dt = 0
                 OR LENGTH(sls_order_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END AS sls_order_dt,

        -- Validate and convert shipping date
        CASE
            WHEN sls_ship_dt = 0
                 OR LENGTH(sls_ship_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END AS sls_ship_dt,

        -- Validate and convert due date
        CASE
            WHEN sls_due_dt = 0
                 OR LENGTH(sls_due_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END AS sls_due_dt,

        -- Recalculate sales if the original value is invalid
        CASE
            WHEN sls_sales IS NULL
                 OR sls_sales <= 0
                 OR sls_sales <> (sls_quantity * sls_price)
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        -- Recalculate price if the original price is invalid
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price

    FROM bronze.crm_sales_details;


    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);

    SELECT COUNT(*)
    INTO total_rows
    FROM silver.crm_sales_details;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';


    -- =========================================================
    -- SECTION 2: LOAD ERP TABLES
    -- =========================================================

    RAISE NOTICE '--------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '--------------------------------------------------';


    -- ---------------------------------------------------------
    -- 4. Load ERP Customer Information
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: silver.erp_cust_az12';

    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE '>> Transforming and loading silver.erp_cust_az12';

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        -- Remove NAS prefix from customer ID
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
            ELSE cid
        END AS cid,

        -- Validate birth dates
        CASE
            WHEN bdate > CURRENT_DATE
                 OR bdate < DATE '1925-01-01'
                THEN NULL
            ELSE bdate
        END AS bdate,

        -- Standardize gender values
        CASE
            WHEN UPPER(TRIM(gen)) = 'M'
                 OR UPPER(TRIM(gen)) = 'MALE'
                THEN 'Male'
            WHEN UPPER(TRIM(gen)) = 'F'
                 OR UPPER(TRIM(gen)) = 'FEMALE'
                THEN 'Female'
            ELSE 'n/a'
        END AS gen

    FROM bronze.erp_cust_az12;


    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);

    SELECT COUNT(*)
    INTO total_rows
    FROM silver.erp_cust_az12;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';


    -- ---------------------------------------------------------
    -- 5. Load ERP Customer Locations
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: silver.erp_loc_a101';

    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE '>> Transforming and loading silver.erp_loc_a101';

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        -- Remove hyphens from customer ID
        REPLACE(cid, '-', '') AS cid,

        -- Standardize country names and handle missing values
        CASE
            WHEN cntry IS NULL OR LENGTH(TRIM(cntry)) = 0
                THEN 'n/a'
            WHEN UPPER(TRIM(cntry)) IN ('US', 'USA', 'UNITED STATES')
                THEN 'United States'
            WHEN UPPER(TRIM(cntry)) = 'DE'
                THEN 'Germany'
            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101;


    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);

    SELECT COUNT(*)
    INTO total_rows
    FROM silver.erp_loc_a101;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';


    -- ---------------------------------------------------------
    -- 6. Load ERP Product Categories
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: silver.erp_px_cat_g1v2';

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE '>> Transforming and loading silver.erp_px_cat_g1v2';

    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat_g1v2;


    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC, 2);

    SELECT COUNT(*)
    INTO total_rows
    FROM silver.erp_px_cat_g1v2;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';


    -- =========================================================
    -- END: SILVER LAYER DATA LOADING
    -- =========================================================

    -- Calculate total procedure execution time
    p_end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Silver Layer Loading Completed Successfully';
    RAISE NOTICE '>> Total Execution Duration: % seconds',
        ROUND(
            EXTRACT(EPOCH FROM (p_end_time - p_start_time))::NUMERIC,
            2
        );
    RAISE NOTICE '=================================================';


EXCEPTION

    -- Handle unexpected errors during the loading process
    WHEN OTHERS THEN

        RAISE NOTICE '=================================================';
        RAISE NOTICE 'ERROR OCCURRED DURING SILVER LAYER LOADING';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'Error SQLSTATE: %', SQLSTATE;
        RAISE NOTICE '=================================================';

        -- Re-throw the error so the calling client knows
        -- that the Silver Layer loading process has failed
        RAISE;

END;
$$;


-- ============================================================
-- EXECUTE THE SILVER LAYER DATA LOADING PROCEDURE
-- ============================================================

CALL silver.load_dataset();
