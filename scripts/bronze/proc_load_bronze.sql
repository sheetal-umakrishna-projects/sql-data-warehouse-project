/*
===============================================================================
Not done yet -> Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    - Loads data into the 'bronze' table from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Stored procedures aren't used yet cause loading CSV file via LOCAL INFILE doesn't allow to use stored procedure -> finding an alternative soon.

If stored procedure is used later then ->
  Parameters:
      None. 
  	  This stored procedure does not accept any parameters or return any values.
  
  Usage Example:
      EXEC bronze.load_bronze;
===============================================================================
*/

USE DataWarehouse;

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;

TRUNCATE TABLE bronze_crm_cust_info;
LOAD DATA LOCAL INFILE '/Users/sheetalumakrishna/Desktop/sql-data-warehouse-project-main/datasets/source_crm/cust_info.csv'
INTO TABLE bronze_crm_cust_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


TRUNCATE TABLE bronze_crm_prod_info;
LOAD DATA LOCAL INFILE '/Users/sheetalumakrishna/Desktop/sql-data-warehouse-project-main/datasets/source_crm/prd_info.csv'
INTO TABLE bronze_crm_prod_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


TRUNCATE TABLE bronze_crm_sales_details;
LOAD DATA LOCAL INFILE '/Users/sheetalumakrishna/Desktop/sql-data-warehouse-project-main/datasets/source_crm/sales_details.csv'
INTO TABLE bronze_crm_sales_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


TRUNCATE TABLE bronze_erp_loc_a101;
LOAD DATA LOCAL INFILE '/Users/sheetalumakrishna/Desktop/sql-data-warehouse-project-main/datasets/source_erp/LOC_A101.csv'
INTO TABLE bronze_erp_loc_a101
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


TRUNCATE TABLE bronze_erp_cust_az12;
LOAD DATA LOCAL INFILE '/Users/sheetalumakrishna/Desktop/sql-data-warehouse-project-main/datasets/source_erp/CUST_AZ12.csv'
INTO TABLE bronze_erp_cust_az12
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


TRUNCATE TABLE bronze_erp_px_cat_g1v2;
LOAD DATA LOCAL INFILE '/Users/sheetalumakrishna/Desktop/sql-data-warehouse-project-main/datasets/source_erp/PX_CAT_G1V2.csv'
INTO TABLE bronze_erp_px_cat_g1v2
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM bronze_crm_cust_info;
SELECT COUNT(*) FROM bronze_crm_prod_info;
SELECT COUNT(*) FROM bronze_crm_sales_details;
SELECT COUNT(*) FROM bronze_erp_loc_a101;
SELECT COUNT(*) FROM bronze_erp_cust_az12;
SELECT COUNT(*) FROM bronze_erp_px_cat_g1v2;
