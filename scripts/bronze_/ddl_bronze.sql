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

CREATE OR REPLACE PROCEDURE bronze.load_file(
    p_table_name TEXT,
    p_file_path  TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;
    v_error_msg  TEXT;
BEGIN
    v_start_time := clock_timestamp();

    EXECUTE format('TRUNCATE TABLE %s', p_table_name);

    EXECUTE format(
        'COPY %s FROM %L DELIMITER '','' CSV HEADER',
        p_table_name,
        p_file_path
    );

    v_end_time := clock_timestamp();

    RAISE NOTICE '>> SUCCESS: %', p_table_name;
    RAISE NOTICE '>> Load Duration = % seconds',
        ROUND(EXTRACT(EPOCH FROM (v_end_time - v_start_time)), 2);

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;

        RAISE NOTICE '>> FAILED: %', p_table_name;
        RAISE NOTICE '>> Error: %', v_error_msg;
END;
$$;

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
BEGIN

    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '============================================================';

    RAISE NOTICE 'Loading CRM Tables';

    CALL bronze.load_file(
        'bronze.crm_cust_info',
        'D:/Kashyap/Data Engineering/SQL Data Warehouse from Scratch/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
    );

    CALL bronze.load_file(
        'bronze.crm_prod_info',
        'D:/Kashyap/Data Engineering/SQL Data Warehouse from Scratch/sql-data-warehouse-project/datasets/source_crm/prod_info.csv'
    );

    CALL bronze.load_file(
        'bronze.crm_sales_details',
        'D:/Kashyap/Data Engineering/SQL Data Warehouse from Scratch/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
    );

    RAISE NOTICE 'Loading ERP Tables';

    CALL bronze.load_file(
        'bronze.erp_cust_az12',
        'D:/Kashyap/Data Engineering/SQL Data Warehouse from Scratch/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
    );

    CALL bronze.load_file(
        'bronze.erp_loc_a101',
        'D:/Kashyap/Data Engineering/SQL Data Warehouse from Scratch/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
    );

    CALL bronze.load_file(
        'bronze.erp_px_cat_g1v2',
        'D:/Kashyap/Data Engineering/SQL Data Warehouse from Scratch/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
    );

    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Bronze Layer Load Completed';
    RAISE NOTICE '============================================================';

END;
$$;


-- call bronze.load_bronze()
