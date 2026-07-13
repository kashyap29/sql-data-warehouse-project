/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

DROP TABLE IF EXISTS bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr VARCHAR(50),
    cst_create_date DATE
);

CREATE SCHEMA IF NOT EXISTS bronze;
drop table if exists bronze.crm_sales_details;
create table bronze.crm_sales_details (
sls_ord_num varchar(50), 
sls_prd_key varchar(50), 
sls_cust_id int, 
sls_order_dt varchar(50),
sls_ship_dt varchar(50),
sls_due_dt varchar(50),
sls_sales int, 
sls_quantity int, 
sls_price int
);

drop table if exists bronze.erp_cust_az12;
create table bronze.erp_cust_az12 (
cid varchar(50),	
bdate date,	
gen varchar(50)
);

drop table if exists bronze.erp_loc_a101;
create table bronze.erp_loc_a101 (
cid varchar(50),	
cntry varchar(50)	
);

drop table if exists bronze.erp_px_cat_g1v2;
create table bronze.erp_px_cat_g1v2 (
id varchar(50),
cat varchar(50),
subcat varchar(50),
maintenance varchar(50)	
);

