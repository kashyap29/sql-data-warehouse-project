/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

create or REPLACE procedure silver.load_silver()
LANGUAGE plpgsql
AS $$
begin

	RAISE NOTICE '================== Truncating silver.crm_cust_info tbl ================================';
	truncate table silver.crm_cust_info;
	RAISE NOTICE '================== Inserting silver.crm_cust_info tbl ================================';
	insert into silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
	)
	
	select
	cst_id,
	cst_key,
	trim(cst_firstname) as cst_firstname,
	trim(cst_lastname) as cst_lastname,
	case when upper(trim(cst_marital_status)) = 'M' then 'Married'
		when upper(trim(cst_marital_status)) = 'S' then 'Single'
		else 'n/a'
		end as cst_marital_status,
	case when upper(trim(cst_gndr)) = 'M' then 'Male'
		when upper(trim(cst_gndr)) = 'F' then 'Female'
		else 'n/a'
		end as cst_gndr,
	cst_create_date
	
	from
	(
	select *,
	row_number() over(partition by cst_id order by cst_create_date desc) as flag_last
	from bronze.crm_cust_info
	)t
	where t.flag_last =1;
	
	
	RAISE NOTICE '================== Truncating silver.crm_prod_info tbl ================================';
	truncate table silver.crm_prod_info;
	RAISE NOTICE '================== Inserting silver.crm_prod_info tbl ================================';
	insert into silver.crm_prod_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm ,
	prd_cost,
	prd_line ,
	prd_start_dt ,
	prd_end_dt
	)
	
	select
	prd_id,
	replace(substring(prd_key,1,5),'-','_') as cat_id,
	substring(prd_key,7,length(prd_key)) as prd_key,
	prd_nm,
	COALESCE(prd_cost, 0) as prd_cost,
	case upper(trim(prd_line))
		when 'M' then 'Mountain'
		when 'R' then 'Road'
		when 'S' then 'Other Sales'
		when 'T' then 'Touring'
		else 'n/a'
		end as prd_line,
	(prd_start_dt) :: DATE as prd_start_dt,
	(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt asc) - INTERVAL '1 day') :: date as prd_end_dt
	from bronze.crm_prod_info;
	
	RAISE NOTICE '================== Truncating silver.crm_sales_details tbl ================================';
	truncate table silver.crm_sales_details;
	RAISE NOTICE '================== Inserting silver.crm_sales_details tbl ================================';
	insert into silver.crm_sales_details
	(
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
	case when sls_order_dt= '0' or length(sls_order_dt) <> 8 then Null
		else  TO_DATE(sls_order_dt::VARCHAR, 'YYYYMMDD') end as sls_order_dt ,
	case when sls_ship_dt= '0' or length(sls_ship_dt) <> 8 then Null
		else  TO_DATE(sls_ship_dt::VARCHAR, 'YYYYMMDD') end as sls_ship_dt ,
	case when sls_due_dt= '0' or length(sls_due_dt) <> 8 then Null
		else  TO_DATE(sls_due_dt::VARCHAR, 'YYYYMMDD') end as sls_due_dt ,
	
	case when sls_sales is null or sls_sales <=0 or (sls_sales != (sls_quantity * abs(sls_price))) then (sls_quantity * abs(sls_price))
		else sls_sales 
		end sls_sales,
	abs(sls_quantity) as sls_quantity,
	case when sls_price is null or sls_price <=0  then sls_sales/coalesce(sls_quantity,0) else sls_price end as sls_price
	
	FROM bronze.crm_sales_details;
	
	
	RAISE NOTICE '================== Truncating silver.erp_cust_az12 tbl ================================';
	truncate table silver.erp_cust_az12;
	RAISE NOTICE '================== Inserting silver.erp_cust_az12 tbl ================================';
	insert into silver.erp_cust_az12
	(
	cid, 
	bdate,
	gen
	)
	select 
	case when cid like 'NAS%' then substring(cid,4,length(cid)) else cid end as cid, 
	case when bdate > CURRENT_DATE then null else bdate end as bdate, 
	case when upper(trim(gen)) in ('F','FEMALE') then 'Female'	
		when upper(trim(gen)) in ('M','MALE') then 'Male'
		else 'n/a'
		end as gen
	from bronze.erp_cust_az12;
	
	
	RAISE NOTICE '================== Truncating silver.erp_loc_a101 tbl ================================';
	truncate table silver.erp_loc_a101;
	RAISE NOTICE '================== Inserting silver.erp_loc_a101 tbl ================================';
	insert into silver.erp_loc_a101
	(
	cid, 
	cntry
	)
	select replace(cid,'-','') as cid,
	case when trim(cntry) = 'DE' then 'Germany'
		when trim(cntry) in ('US','USA') then 'United States'
		when trim(cntry) ='' or trim(cntry) is null then 'n/a'
		else trim(cntry)
		end as cntry
	from bronze.erp_loc_a101;
	
	
	RAISE NOTICE '================== Truncating silver.erp_px_cat_g1v2 tbl ================================';
	truncate table silver.erp_px_cat_g1v2;
	RAISE NOTICE '================== Inserting silver.erp_px_cat_g1v2 tbl ================================';
	insert into silver.erp_px_cat_g1v2 
	(
	id, 
	cat, 
	subcat,
	maintenance
	)
	select 
	id, 
	cat, 
	subcat,
	maintenance
	from bronze.erp_px_cat_g1v2;
	
end
$$
;

CALL silver.load_silver();



