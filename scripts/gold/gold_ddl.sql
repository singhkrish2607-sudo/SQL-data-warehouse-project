
/*
===============================================================================
    GOLD LAYER - DIMENSION AND FACT VIEWS
===============================================================================

    Purpose:
        Create business-ready views in the Gold Layer for analytical
        reporting and business intelligence.

    Views:
        1. gold.dim_customers
        2. gold.dim_products
        3. gold.fact_sales

    Source:
        Silver Layer tables

===============================================================================
*/


-- =============================================================================
-- 1. CUSTOMER DIMENSION VIEW
-- =============================================================================
-- Purpose:
--     Combines customer information from CRM and ERP sources.
--     Creates a surrogate key for customer identification.
--
-- Source Tables:
--     silver.crm_cust_info
--     silver.erp_cust_az12
--     silver.erp_loc_a101
--
-- Business Logic:
--     - CRM is the primary source for customer information.
--     - ERP provides additional customer birthdate and location details.
--     - CRM gender is preferred; ERP gender is used as a fallback.
-- =============================================================================

CREATE VIEW gold.dim_customers AS
SELECT
    -- Generate a surrogate key for customer identification
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    -- Customer identification and personal information
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,

    -- Customer location and demographic information
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,

    -- Use CRM gender as the primary source and ERP as fallback
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    -- Additional customer information
    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info AS ci

-- Retrieve customer birthdate and additional gender information
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ca.cid = ci.cst_key

-- Retrieve customer country information
LEFT JOIN silver.erp_loc_a101 AS la
    ON la.cid = ci.cst_key
;


-- =============================================================================
-- 2. PRODUCT DIMENSION VIEW
-- =============================================================================
-- Purpose:
--     Combines product information from CRM with category details from ERP.
--     Generates a surrogate key for product identification.
--
-- Source Tables:
--     silver.crm_prd_info
--     silver.erp_px_cat_g1v2
--
-- Business Logic:
--     - Combines product details with category information.
--     - Excludes historical product records.
--     - Includes only products where prd_end_dt IS NULL.
-- =============================================================================

CREATE VIEW gold.dim_products AS
SELECT
    -- Generate a surrogate key for product identification
    ROW_NUMBER() OVER (
        ORDER BY pi.prd_start_dt, pi.prd_key
    ) AS product_key,

    -- Product identification and descriptive information
    pi.prd_id AS product_id,
    pi.prd_key AS product_number,
    pi.prd_nm AS product_name,

    -- Product category information
    pi.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance,

    -- Product cost and classification
    pi.prd_cost AS product_cost,
    pi.prd_line AS product_line,

    -- Product validity information
    pi.prd_start_dt AS start_date

FROM silver.crm_prd_info AS pi

-- Retrieve product category and subcategory information
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pc.id = pi.cat_id

-- Include only current product records
WHERE pi.prd_end_dt IS NULL
;


-- =============================================================================
-- 3. SALES FACT VIEW
-- =============================================================================
-- Purpose:
--     Combines sales transaction details with customer and product dimensions.
--     Provides sales measures and dimension surrogate keys for analysis.
--
-- Source Tables:
--     silver.crm_sales_details
--     gold.dim_products
--     gold.dim_customers
--
-- Business Logic:
--     - Retrieves product_key from the product dimension.
--     - Retrieves customer_key from the customer dimension.
--     - Preserves sales records using LEFT JOIN operations.
-- =============================================================================

CREATE VIEW gold.fact_sales AS
SELECT
    -- Sales order identification
    sd.sls_ord_num AS order_number,

    -- Dimension surrogate keys
    pr.product_key AS product_key,
    cs.customer_key AS customer_key,

    -- Sales order date information
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,

    -- Sales measures
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details AS sd

-- Connect sales records with the product dimension
LEFT JOIN gold.dim_products AS pr
    ON pr.product_number = sd.sls_prd_key

-- Connect sales records with the customer dimension
LEFT JOIN gold.dim_customers AS cs
    ON cs.customer_id = sd.sls_cust_id
;


/*
===============================================================================
    END OF GOLD LAYER VIEW CREATION
===============================================================================
*/
```
