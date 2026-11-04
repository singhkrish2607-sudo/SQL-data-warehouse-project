-- Bronze Layer Data Loading Procedure
-- ============================================================
-- Project: Data Warehouse
-- Layer: Bronze
-- Purpose: Load raw CRM and ERP CSV datasets into Bronze tables
-- Database: PostgreSQL
-- ============================================================

CREATE OR REPLACE PROCEDURE bronze.load_dataset()
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variables for measuring individual table load durations
    start_time TIMESTAMP;
    end_time TIMESTAMP;

    -- Variables for measuring total procedure execution time
    p_start_time TIMESTAMP;
    p_end_time TIMESTAMP;

    -- Variable for storing the number of rows loaded into each table
    total_rows BIGINT;

BEGIN
    -- =========================================================
    -- START: BRONZE LAYER DATA LOADING
    -- =========================================================

    -- Record the overall procedure start time
    p_start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '=================================================';
    RAISE NOTICE '             LOADING BRONZE LAYER                ';
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

    -- Remove existing data before reloading the raw dataset
    RAISE NOTICE '>> Truncating table: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;

    -- Import customer information from the source CSV file
    RAISE NOTICE '>> Loading data into bronze.crm_cust_info';

    COPY bronze.crm_cust_info
    FROM 'D:/SQL Project/Data warehouse Project/datasets/sourse_crm/cust_info.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );

    -- Calculate and display the individual table load duration
    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER;

    -- Count and display the loaded customer records
    SELECT COUNT(*)
    INTO total_rows
    FROM bronze.crm_cust_info;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';

    -- ---------------------------------------------------------
    -- 2. Load CRM Product Information
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE '>> Loading data into bronze.crm_prd_info';

    COPY bronze.crm_prd_info
    FROM 'D:/SQL Project/Data warehouse Project/datasets/sourse_crm/PRD_info.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );

    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER;

    SELECT COUNT(*)
    INTO total_rows
    FROM bronze.crm_prd_info;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';

    -- ---------------------------------------------------------
    -- 3. Load CRM Sales Details
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE '>> Loading data into bronze.crm_sales_details';

    COPY bronze.crm_sales_details
    FROM 'D:/SQL Project/Data warehouse Project/datasets/sourse_crm/sales_details.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );

    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER;

    SELECT COUNT(*)
    INTO total_rows
    FROM bronze.crm_sales_details;

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

    RAISE NOTICE '>> Truncating table: bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE '>> Loading data into bronze.erp_cust_az12';

    COPY bronze.erp_cust_az12
    FROM 'D:/SQL Project/Data warehouse Project/datasets/source_erp/CUST_AZ12.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );

    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER;

    SELECT COUNT(*)
    INTO total_rows
    FROM bronze.erp_cust_az12;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';

    -- ---------------------------------------------------------
    -- 5. Load ERP Customer Locations
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE '>> Loading data into bronze.erp_loc_a101';

    COPY bronze.erp_loc_a101
    FROM 'D:/SQL Project/Data warehouse Project/datasets/source_erp/LOC_A101.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );

    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER;

    SELECT COUNT(*)
    INTO total_rows
    FROM bronze.erp_loc_a101;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';

    -- ---------------------------------------------------------
    -- 6. Load ERP Product Categories
    -- ---------------------------------------------------------

    start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating table: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>> Loading data into bronze.erp_px_cat_g1v2';

    COPY bronze.erp_px_cat_g1v2
    FROM 'D:/SQL Project/Data warehouse Project/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (
        FORMAT CSV,
        HEADER TRUE,
        DELIMITER ','
    );

    end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER;

    SELECT COUNT(*)
    INTO total_rows
    FROM bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>> Total Loaded Rows: %', total_rows;
    RAISE NOTICE '--------------------------------------------------';

    -- =========================================================
    -- END: BRONZE LAYER DATA LOADING
    -- =========================================================

    -- Calculate and display the total procedure execution time
    p_end_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Bronze Layer Loading Completed Successfully';
    RAISE NOTICE '>> Total Execution Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (p_end_time - p_start_time))::NUMERIC, 2);
    RAISE NOTICE '=================================================';

EXCEPTION
    -- Handle unexpected errors during the loading process
    WHEN OTHERS THEN
        RAISE NOTICE '=================================================';
        RAISE NOTICE 'ERROR OCCURRED DURING BRONZE LAYER LOADING';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'Error SQLSTATE: %', SQLSTATE;
        RAISE NOTICE '=================================================';

        -- Re-throw the error so the calling client knows the load failed
        RAISE;
END;
$$;

-- ============================================================
-- EXECUTE THE BRONZE LAYER LOADING PROCEDURE
-- ============================================================

CALL bronze.load_dataset();
