
/*
===============================================================================
GOLD LAYER: DATA QUALITY AND INTEGRATION TESTING
===============================================================================

Purpose:
    Validate data integration, dimension views, and referential integrity
    in the Gold Layer.

Validation Sections:
    1. Customer Gender Data Integration
    2. Product Data Integration
    3. Product Dimension Duplicate Check
    4. Gold Dimension View Validation
    5. Sales Fact View Validation
    6. Foreign Key Integrity Check

===============================================================================
*/


-- =============================================================================
-- 1. CUSTOMER GENDER DATA INTEGRATION
-- =============================================================================

-- Purpose:
--     Compare gender values between CRM and ERP customer sources.
--     CRM is considered the primary source for customer gender.
--     ERP gender is used as a fallback when CRM gender is 'n/a'.
--
-- Business Rule:
--     If CRM gender is available, use CRM gender.
--     Otherwise, use ERP gender.
--     If both values are unavailable, default to 'n/a'.
--
-- Note:
--     Gender discrepancies should be reviewed with the business team
--     to confirm the appropriate source of truth.

SELECT
    ci.cst_id,
    ci.cst_key,
    ci.cst_gndr AS crm_gender,
    ca.gen AS erp_gender,

    -- Apply customer gender source-priority logic
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS new_gender

FROM silver.crm_cust_info AS ci

-- Integrate ERP customer information
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ca.cid = ci.cst_key

-- Integrate ERP location information
LEFT JOIN silver.erp_loc_a101 AS la
    ON la.cid = ci.cst_key

-- Identify records where CRM and ERP gender values differ
WHERE ci.cst_gndr <> ca.gen;


-- Validate standardized gender values in the Gold customer dimension
SELECT DISTINCT
    gender
FROM gold.dim_customers;


-- =============================================================================
-- 2. PRODUCT DATA INTEGRATION
-- =============================================================================

-- Purpose:
--     Validate the integration of CRM product information with ERP category
--     information.
--
-- Business Rule:
--     Include only current product records by filtering out historical
--     products where prd_end_dt is populated.

SELECT
    pi.prd_id,
    pi.cat_id,
    pi.prd_key,
    pi.prd_nm,
    pi.prd_cost,
    pi.prd_line,
    pi.prd_start_dt,

    -- ERP category information
    pc.cat,
    pc.subcat,
    pc.maintenance

FROM silver.crm_prd_info AS pi

-- Integrate ERP product category information
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pc.id = pi.cat_id

-- Exclude historical product records
WHERE pi.prd_end_dt IS NULL;


-- =============================================================================
-- 3. PRODUCT DIMENSION DUPLICATE CHECK
-- =============================================================================

-- Purpose:
--     Check whether the current product records contain duplicate product IDs
--     after integrating CRM and ERP product information.
--
-- Expected Result:
--     The query should return no records if product_id is unique.

SELECT
    product_key,
    COUNT(*) AS duplicate_count

FROM gold.dim_products
group by product_key 
having count(*) > 1;
