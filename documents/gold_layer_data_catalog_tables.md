# Gold Layer Data Catalog

This document describes the columns available in the three views created
in the Gold Layer.

## 1. `gold.dim_customers`

**Description:** Customer dimension view combining CRM customer details
with ERP birthdate, gender, and country information.

**Source tables:** `silver.crm_cust_info`, `silver.erp_cust_az12`,
`silver.erp_loc_a101`

  ------------------------------------------------------------------------------------------------------
                    No. Column Name         Description      Source / Logic
  --------------------- ------------------- ---------------- -------------------------------------------
                      1 `customer_key`      Generated        `ROW_NUMBER() OVER (ORDER BY ci.cst_id)`
                                            surrogate key    
                                            for each         
                                            customer record. 

                      2 `customer_id`       Original         `silver.crm_cust_info.cst_id`
                                            customer         
                                            identifier.      

                      3 `customer_number`   Customer         `silver.crm_cust_info.cst_key`
                                            reference number 
                                            used to connect  
                                            CRM and ERP      
                                            records.         

                      4 `first_name`        Customer's first `silver.crm_cust_info.cst_firstname`
                                            name.            

                      5 `last_name`         Customer's last  `silver.crm_cust_info.cst_lastname`
                                            name.            

                      6 `country`           Country          `silver.erp_loc_a101.cntry`
                                            associated with  
                                            the customer.    

                      7 `marital_status`    Customer's       `silver.crm_cust_info.cst_marital_status`
                                            marital status.  

                      8 `gender`            Customer's       `ci.cst_gndr`; fallback: `ca.gen`; default:
                                            gender; CRM      `n/a`
                                            value is         
                                            preferred, with  
                                            ERP used as a    
                                            fallback when    
                                            CRM is `n/a`.    

                      9 `birthdate`         Customer's date  `silver.erp_cust_az12.bdate`
                                            of birth.        

                     10 `create_date`       Date the         `silver.crm_cust_info.cst_create_date`
                                            customer record  
                                            was created.     
  ------------------------------------------------------------------------------------------------------

## 2. `gold.dim_products`

**Description:** Product dimension view combining CRM product details
with ERP category, subcategory, and maintenance information. Only
records with `prd_end_dt IS NULL` are included.

**Source tables:** `silver.crm_prd_info`, `silver.erp_px_cat_g1v2`

  -----------------------------------------------------------------------------------------------------------------------
                    No. Column Name        Description       Source / Logic
  --------------------- ------------------ ----------------- ------------------------------------------------------------
                      1 `product_key`      Generated         `ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key)`
                                           surrogate key for 
                                           the product       
                                           record.           

                      2 `product_id`       Original product  `silver.crm_prd_info.prd_id`
                                           identifier.       

                      3 `product_number`   Product reference `silver.crm_prd_info.prd_key`
                                           number.           

                      4 `product_name`     Name of the       `silver.crm_prd_info.prd_nm`
                                           product.          

                      5 `category_id`      Identifier of the `silver.crm_prd_info.cat_id`
                                           product category. 

                      6 `category`         Product category  `silver.erp_px_cat_g1v2.cat`
                                           name.             

                      7 `subcategory`      Product           `silver.erp_px_cat_g1v2.subcat`
                                           subcategory name. 

                      8 `maintenance`      Maintenance       `silver.erp_px_cat_g1v2.maintenance`
                                           information for   
                                           the product       
                                           category.         

                      9 `product_cost`     Cost recorded for `silver.crm_prd_info.prd_cost`
                                           the product.      

                     10 `product_line`     Product line      `silver.crm_prd_info.prd_line`
                                           classification.   

                     11 `start_date`       Start date of the `silver.crm_prd_info.prd_start_dt`
                                           product record.   
  -----------------------------------------------------------------------------------------------------------------------

**Filter applied:** `WHERE pi.prd_end_dt IS NULL`

## 3. `gold.fact_sales`

**Description:** Sales fact view containing sales transaction details,
linked to customer and product dimension keys.

**Source tables:** `silver.crm_sales_details`, `gold.dim_products`,
`gold.dim_customers`

  --------------------------------------------------------------------------------------------------
                    No. Column Name       Description      Source / Logic
  --------------------- ----------------- ---------------- -----------------------------------------
                      1 `order_number`    Sales order      `silver.crm_sales_details.sls_ord_num`
                                          number.          

                      2 `product_key`     Surrogate key of `gold.dim_products.product_key`, matched
                                          the related      using `product_number = sls_prd_key`
                                          product.         

                      3 `customer_key`    Surrogate key of `gold.dim_customers.customer_key`,
                                          the related      matched using `customer_id = sls_cust_id`
                                          customer.        

                      4 `order_date`      Date the sales   `silver.crm_sales_details.sls_order_dt`
                                          order was        
                                          placed.          

                      5 `shipping_date`   Date the order   `silver.crm_sales_details.sls_ship_dt`
                                          was shipped.     

                      6 `due_date`        Due date         `silver.crm_sales_details.sls_due_dt`
                                          associated with  
                                          the sales order. 

                      7 `sales_amount`    Sales amount     `silver.crm_sales_details.sls_sales`
                                          recorded for the 
                                          transaction.     

                      8 `quantity`        Quantity of      `silver.crm_sales_details.sls_quantity`
                                          products sold in 
                                          the transaction. 

                      9 `price`           Price recorded   `silver.crm_sales_details.sls_price`
                                          for the          
                                          transaction.     
  --------------------------------------------------------------------------------------------------

## 4. View Summary

  ------------------------------------------------------------------------------
  View Name              View Type            Number of Columns Purpose
  ---------------------- ---------------- --------------------- ----------------
  `gold.dim_customers`   Dimension                           10 Stores customer
                                                                profile
                                                                information.

  `gold.dim_products`    Dimension                           11 Stores current
                                                                product and
                                                                category
                                                                information.

  `gold.fact_sales`      Fact                                 9 Stores sales
                                                                transaction
                                                                details and
                                                                measures.
  ------------------------------------------------------------------------------

## 5. Relationships

  ------------------------------------------------------------------------------
  Fact View           Fact Column       Dimension View         Dimension Column
  ------------------- ----------------- ---------------------- -----------------
  `gold.fact_sales`   `customer_key`    `gold.dim_customers`   `customer_key`

  `gold.fact_sales`   `product_key`     `gold.dim_products`    `product_key`
  ------------------------------------------------------------------------------

**Note:** The surrogate keys are generated using `ROW_NUMBER()` in the
views. Their values are calculated when queried and may change if the
underlying data or ordering changes. The fact view uses `LEFT JOIN`, so
its customer or product key may be NULL when no matching dimension
record exists.
