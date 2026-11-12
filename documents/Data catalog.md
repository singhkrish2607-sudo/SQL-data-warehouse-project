# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of **dimension views** and a **fact view** for specific business metrics, built on top of the Silver Layer.

---

### 1. **gold.dim_customers**
- **Purpose:** Stores customer details enriched with demographic and geographic data.
- **Source tables:** `silver.crm_cust_info`, `silver.erp_cust_az12`, `silver.erp_loc_a101`
- **Columns:**

| Column Name      | Data Type     | Description                                                                                                        |
|------------------|---------------|--------------------------------------------------------------------------------------------------------------------|
| customer_key     | INT           | Surrogate key uniquely identifying each customer record in the dimension view, generated with `ROW_NUMBER()`.      |
| customer_id      | INT           | Unique numerical identifier assigned to each customer.                                                             |
| customer_number  | NVARCHAR(50)  | Alphanumeric identifier representing the customer, used to connect CRM and ERP records.                            |
| first_name       | NVARCHAR(50)  | The customer's first name, as recorded in the system.                                                              |
| last_name        | NVARCHAR(50)  | The customer's last name or family name.                                                                           |
| country          | NVARCHAR(50)  | The country associated with the customer (e.g., 'Australia').                                                      |
| marital_status   | NVARCHAR(50)  | The marital status of the customer (e.g., 'Married', 'Single').                                                    |
| gender           | NVARCHAR(50)  | The gender of the customer (e.g., 'Male', 'Female', 'n/a'). CRM value is preferred; ERP is used when CRM is 'n/a'. |
| birthdate        | DATE          | The date of birth of the customer, formatted as YYYY-MM-DD (e.g., 1971-10-06).                                     |
| create_date      | DATE          | The date the customer record was created in the system.                                                            |

---

### 2. **gold.dim_products**
- **Purpose:** Provides information about the products and their attributes. Only current records (`prd_end_dt IS NULL`) are included.
- **Source tables:** `silver.crm_prd_info`, `silver.erp_px_cat_g1v2`
- **Columns:**

| Column Name     | Data Type     | Description                                                                                          |
|-----------------|---------------|------------------------------------------------------------------------------------------------------|
| product_key     | INT           | Surrogate key uniquely identifying each product record in the product dimension view.                |
| product_id      | INT           | A unique identifier assigned to the product for internal tracking and referencing.                   |
| product_number  | NVARCHAR(50)  | A structured alphanumeric code representing the product, often used for categorization or inventory. |
| product_name    | NVARCHAR(50)  | Descriptive name of the product, including key details such as type, color, and size.                |
| category_id     | NVARCHAR(50)  | A unique identifier for the product's category, linking to its high-level classification.            |
| category        | NVARCHAR(50)  | The broader classification of the product (e.g., Bikes, Components) to group related items.          |
| subcategory     | NVARCHAR(50)  | A more detailed classification of the product within the category, such as product type.             |
| maintenance     | NVARCHAR(50)  | Indicates whether the product requires maintenance (e.g., 'Yes', 'No').                              |
| product_cost    | INT           | The cost or base price of the product, measured in monetary units.                                   |
| product_line    | NVARCHAR(50)  | The specific product line or series to which the product belongs (e.g., Road, Mountain).             |
| start_date      | DATE          | The date when the product record became effective, formatted as YYYY-MM-DD.                          |

---

### 3. **gold.fact_sales**
- **Purpose:** Stores transactional sales data for analytical purposes.
- **Source tables:** `silver.crm_sales_details`, `gold.dim_products`, `gold.dim_customers`
- **Columns:**

| Column Name   | Data Type     | Description                                                                                          |
|---------------|---------------|------------------------------------------------------------------------------------------------------|
| order_number  | NVARCHAR(50)  | A unique alphanumeric identifier for each sales order (e.g., 'SO54496').                             |
| product_key   | INT           | Surrogate key linking the order to the product dimension view (matched on `product_number`).         |
| customer_key  | INT           | Surrogate key linking the order to the customer dimension view (matched on `customer_id`).           |
| order_date    | DATE          | The date when the order was placed.                                                                  |
| shipping_date | DATE          | The date when the order was shipped to the customer.                                                 |
| due_date      | DATE          | The date when the order payment was due.                                                             |
| sales_amount  | INT           | The total monetary value of the sale for the line item, in whole currency units (e.g., 25).          |
| quantity      | INT           | The number of units of the product ordered for the line item (e.g., 1).                              |
| price         | INT           | The price per unit of the product for the line item, in whole currency units (e.g., 25).             |

---

### Relationships

| Fact View         | Fact Column    | Dimension View       | Dimension Column |
|-------------------|----------------|----------------------|------------------|
| `gold.fact_sales` | `customer_key` | `gold.dim_customers` | `customer_key`   |
| `gold.fact_sales` | `product_key`  | `gold.dim_products`  | `product_key`    |

> **Note:** Surrogate keys are generated with `ROW_NUMBER()` inside the views, so their values are calculated at query time and may change if the underlying data or ordering changes. The fact view uses `LEFT JOIN`, so `customer_key` or `product_key` can be `NULL` when no matching dimension record exists.
