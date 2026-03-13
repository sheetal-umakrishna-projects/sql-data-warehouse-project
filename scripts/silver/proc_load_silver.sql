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

-- We need to make sure we truncate and then insert all the tables, just like in bronze layer
-- Insert new transformed data of cust_info into the silver table

-- To execute the stored procedure
-- DROP PROCEDURE IF EXISTS silver_load_silver;

-- Change delimiter to $$
DELIMITER $$

CREATE PROCEDURE silver_load_silver()
BEGIN

	SELECT 'Truncating Table : silver_crm_cust_info' AS msg ;
	TRUNCATE TABLE silver_crm_cust_info ; 
	SELECT 'Inserting Data Into : silver_crm_cust_info' AS msg ;
	INSERT INTO silver_crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
		
	)
	SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname, -- Trimming -> Removing unwanted spaces 
	TRIM(cst_lastname) AS cst_lastname,
	CASE 
		WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'  -- Data Normalization/Standardization 
		WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		ELSE 'n/a'                                                -- Handling missing values or Null Values
	END AS cst_marital_status,

	CASE 
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
		ELSE 'n/a'
	END AS cst_gndr,
	cst_create_date
	FROM(
		SELECT 
		* , 
		ROW_NUMBER() OVER (                   -- Remove deduplicates
			PARTITION BY cst_id 
			ORDER BY cst_create_date DESC
		) AS flag_last
		FROM bronze_crm_cust_info
		WHERE cst_id <> 0
	) t 
	WHERE flag_last = 1 ;

	-- Insert new transformed data of prod_info into the silver table


	SELECT 'Truncating Table : silver_crm_prod_info' AS msg ;
	TRUNCATE TABLE silver_crm_prod_info ; 
	SELECT 'Inserting Data Into : silver_crm_prod_info' AS msg ;

	INSERT INTO silver_crm_prod_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt

	)
	SELECT
	prd_id,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,    -- Extract category ID  -> also Dervied Columns
	SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,		  -- Extract product key -> also Dervied Columns
	prd_nm,
	IFNULL(prd_cost, 0) AS prd_cost,						  -- Handling missing information
	CASE UPPER(TRIM(prd_line))								  -- Data Normalization
		WHEN 'R' THEN 'Road'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'M' THEN 'Mountain'
		WHEN 'T' THEN 'Touring'
		ELSE 'n/a'											  -- Handled missing
	END AS prd_line,										  -- Map product line codes to descriptive values 
	DATE (prd_start_dt) AS prd_start_dt,					  -- Supposed to be casting but MySQL didn't allow so we used DATE()
	DATE(
		DATE_SUB(
			LEAD(prd_start_dt) OVER (
				PARTITION BY prd_key
				ORDER BY prd_start_dt
			),
			INTERVAL 1 DAY
		)
	) AS prd_end_dt											  -- Calculate end date as one day before the next start date 

	FROM bronze_crm_prod_info ;

	-- Insert new transformed data of crm_sales_details into the silver table

	-- SELECT 'Truncating Table : silver_crm_sales_details' AS msg ;
	-- TRUNCATE TABLE silver_crm_sales_details ; 
	-- SELECT 'Inserting Data Into : silver_crm_sales_details' AS msg ;

	-- INSERT INTO silver_crm_sales_details (
		-- sls_ord_num,
		-- sls_prd_key,
		-- sls_cust_id,
		-- sls_order_dt,
		-- sls_ship_dt,
		-- sls_due_dt,
		-- sls_sales,
		-- sls_quantity,
		-- sls_price

	-- )
	-- SELECT 
		-- sls_ord_num,
		-- sls_prd_key,
		-- sls_cust_id,
		-- CASE 
			-- WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt)!= 8 THEN NULL     -- Handling invalid data 
			-- ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')			-- Data Type casting -> changing data to correct type
		-- END AS sls_order_dt,
		
		-- CASE 
			-- WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt)!= 8 THEN NULL
			-- ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
		-- END AS sls_ship_dt,
		
		-- CASE 
			-- WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt)!= 8 THEN NULL
			-- ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d')
		-- END AS sls_due_dt,
		
		-- CASE 
			-- WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)  	-- Handling the missing data, invalid data by deriving the column by already existing one
			-- THEN sls_quantity * ABS(sls_price)
			-- ELSE sls_sales
		-- END AS sls_sales,																				-- Recalculate sales if original value is missing or incorrect
		
		-- CASE 
			-- WHEN sls_price IS NULL OR sls_price <= 0
			-- THEN sls_sales / NULLIF(sls_quantity, 0)
			-- ELSE sls_price
		-- END AS sls_price,																				-- Derive price if original value is invalid

		-- sls_quantity

	-- FROM bronze_crm_sales_details ;


	-- Updating above code:

	SELECT 'Truncating Table : silver_crm_sales_details' AS msg ;
	TRUNCATE TABLE silver_crm_sales_details ; 
	SELECT 'Inserting Data Into : silver_crm_sales_details' AS msg ;
	INSERT INTO silver_crm_sales_details (
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

		-- Fix order date
		CASE 
			WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 THEN NULL
			ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
		END AS sls_order_dt,

		-- Fix ship date
		CASE 
			WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 THEN NULL
			ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
		END AS sls_ship_dt,

		-- Fix due date
		CASE 
			WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 THEN NULL
			ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d')
		END AS sls_due_dt,

		-- Correct price first (Rule 2 & 3)
		CASE
			WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
			ELSE ABS(sls_price)
		END AS sls_price_corrected,

		-- Quantity stays as-is
		sls_quantity,

		-- Correct sales using corrected price (Rule 1)
		CASE
			WHEN sls_sales IS NULL 
				 OR sls_sales <= 0 
				 OR sls_sales != sls_quantity * 
					CASE
						WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
						ELSE ABS(sls_price)
					END
			THEN sls_quantity *
				 CASE
					 WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
					 ELSE ABS(sls_price)
				 END
			ELSE sls_sales
		END AS sls_sales_corrected

	FROM bronze_crm_sales_details;


	-- Insert new transformed erp_cust_az12 into silver table 


	SELECT 'Truncating Table : silver_erp_cust_az12' AS msg ;
	TRUNCATE TABLE silver_erp_cust_az12 ; 
	SELECT 'Inserting Data Into : silver_erp_cust_az12' AS msg ;

	INSERT INTO silver_erp_cust_az12 (
		cid, 
		bdate,
		gen
	)

	SELECT 
	CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))        -- We handled invalid values -> Remove 'NAS' prefix if present in the field
		ELSE cid
	END AS cid,
	CASE 
		WHEN bdate > CURDATE() THEN NULL								-- We handled invalid values -> Kept old dates but set future birthdates to NULL
		ELSE bdate
	END AS bdate,
	CASE
			WHEN gen IS NULL OR TRIM(gen) = '' THEN 'n/a'
			WHEN LEFT(UPPER(TRIM(gen)),1) = 'F' THEN 'Female'
			WHEN LEFT(UPPER(TRIM(gen)),1) = 'M' THEN 'Male'
			ELSE 'n/a'
		END AS gen
	FROM bronze_erp_cust_az12 ;											-- Normalized gender values and handled unknown cases -> by maping the gender to more friendly values


	-- Now we go back and test the silver erp cust table if all is ok 

	-- Insert the transformed erp_loc file into silver table


	SELECT 'Truncating Table : silver_erp_loc_a101' AS msg ;
	TRUNCATE TABLE silver_erp_loc_a101 ; 
	SELECT 'Inserting Data Into : silver_erp_loc_a101' AS msg ;

	INSERT INTO silver_erp_loc_a101 (
		cid,
		cntry
	)
	SELECT 
	REPLACE(cid, '-', '') AS cid,
	CASE 
		WHEN (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', ''))) = 'DE' 
			THEN 'Germany'
		WHEN (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', ''))) IN ('US','USA') 
			THEN 'United States'
		WHEN cntry IS NULL OR TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', '')) = '' 
			THEN 'n/a'
		ELSE (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', '')))
	END AS cntry

	FROM bronze_erp_loc_a101 ;


	-- Now we go back and test the silver erp cust table if all is ok 


	-- Insert transformed bronze_erp_px_cat table to silver table

	SELECT 'Truncating Table : silver_erp_px_cat_g1v2' AS msg ;
	TRUNCATE TABLE silver_erp_px_cat_g1v2 ; 
	SELECT 'Inserting Data Into : silver_erp_px_cat_g1v2' AS msg ;



	INSERT INTO silver_erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
	)
	SELECT 
	id,
	cat,
	subcat,
	TRIM(REPLACE(REPLACE(maintenance, '\r', ''), '\n', '')) AS maintenance
	FROM bronze_erp_px_cat_g1v2 ;

END $$

-- Reset delimiter back to default
DELIMITER ;

-- To execute the stored procedure:
-- CALL silver_load_silver();
