/*
===============================================================================
Project      : Data Warehouse
Database     : DataWarehouse
Platform     : PostgreSQL
Architecture : Medallion Architecture
Layers       : Bronze (Raw), Silver (Cleaned), Gold (Business-Ready)

PURPOSE:
    Initialize the data warehouse database and create the schemas
    required to organize data processing and analytics.

WARNING:
    Dropping the database permanently deletes all its tables, schemas,
    and data. Make sure you have a backup before running this script.

    PostgreSQL does not allow DROP DATABASE or CREATE DATABASE
    inside a transaction block. Run these commands separately.
===============================================================================
*/




-- 1. Create the database
-- Note: PostgreSQL does not allow DROP DATABASE inside a
-- transaction. Run this command separately if needed.

DROP DATABASE IF EXISTS "DataWarehouse";

CREATE DATABASE "DataWarehouse";


-- ============================================================
-- IMPORTANT:
-- Connect to the "DataWarehouse" database before executing
-- the remaining commands.
-- In pgAdmin, open the Query Tool for DataWarehouse.
-- ============================================================


-- 2. Create the Bronze schema
-- Purpose: Store raw data directly from source systems.

CREATE SCHEMA IF NOT EXISTS bronze;


-- 3. Create the Silver schema
-- Purpose: Store cleaned, standardized, and validated data.

CREATE SCHEMA IF NOT EXISTS silver;


-- 4. Create the Gold schema
-- Purpose: Store business-ready data for reporting and analytics.

CREATE SCHEMA IF NOT EXISTS gold;


-- ============================================================
-- Database initialization completed.
-- Next steps: Create tables and develop ETL/ELT pipelines.
-- ============================================================
