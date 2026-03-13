/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- These are self checks which still need to be structured well
-- These checks were first performed in Bronze table first 
-- Currently updated to silver table so everything works as expected


-- First we do quality check for bronze_crm_cust_info csv file then later files

-- Check For Nulls or Duplicates in Primary Key
-- Expection: No Result -> we ended up getting null and duplicate values

USE DataWarehouse;

SELECT * FROM silver_crm_cust_info;

SELECT cst_id, 
COUNT(*) 
FROM silver_crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL ;

-- Query that does data transformation and data cleansing
-- Remove duplicate cst_ids -> we assign a unique number to each row called flag_last
-- use ROW_NUMBER() for deduplicating -> remove duplicate records so each cst_id appears only once
-- flag_last = 1 -> Keep only newest record based on cst_id

SELECT * 
FROM(
	SELECT 
    * , 
    ROW_NUMBER() OVER (
		PARTITION BY cst_id 
        ORDER BY cst_create_date DESC
	) AS flag_last
	FROM silver_crm_cust_info
) t 
WHERE flag_last = 1 ;

-- Check for unwanted spaces 
-- Expectation: No Results
-- Below can be done for all the string values

SELECT cst_firstname
FROM silver_crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
;

SELECT cst_lastname
FROM silver_crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)
;
-- We get results in above query which was not expected. So next,

SELECT cst_gndr
FROM silver_crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)
;
-- cst_gndr is clean cause it did not give any result which is what was expected in this query

-- Transformation query to clean up the column which didnt give clean results -> firstname and lastname

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
FROM(
	SELECT 
    * , 
    ROW_NUMBER() OVER (
		PARTITION BY cst_id 
        ORDER BY cst_create_date DESC
	) AS flag_last
	FROM silver_crm_cust_info
) t 
WHERE flag_last = 1 ;

-- So the unwanted space in cst_firstname and cst_lastname will be remove by the above

-- Next quality check, is the check the consistency of values in low cardinality columns

-- Data Standardization & Consistency -> check data data consistency in those 2 columns -> cst_marital_status and cst_gndr

SELECT DISTINCT cst_gndr
FROM silver_crm_cust_info ;

SELECT DISTINCT cst_marital_status
FROM silver_crm_cust_info ;

-- Convert the abbreviated values into meaningful words
-- For example:
-- CASE
-- 	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
-- 	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
--     ELSE 'n/a'
-- END AS cst_marital_status,


-- Now final quality check query looks like this which has transformed all the data and also inserted the values into the silver table from bronze table

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
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE 
	WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
    ELSE 'n/a'
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
    ROW_NUMBER() OVER (
		PARTITION BY cst_id 
        ORDER BY cst_create_date DESC
	) AS flag_last
	FROM bronze_crm_cust_info
    WHERE cst_id <> 0
) t 
WHERE flag_last = 1 ;


select * from silver_crm_cust_info;

select COUNT(*) from silver_crm_cust_info;

select COUNT(*) from bronze_crm_cust_info;


-- Next, we check for bronze_crm_prod_info file
-- It is not updated to silver_table prod_info cause we rechecked if the data cleaned and transformed in silver table after the transformation


SELECT * FROM bronze_crm_prod_info ;

-- Check for duplicates in primary key which is prd_id

SELECT prd_id, 
COUNT(*) 
FROM bronze_crm_prod_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL ;

-- There are no duplicates or nulls in the primary key prd_id in bronze_cem_prod_info table

SELECT * FROM bronze_crm_prod_info ;

-- There are a lot of info in prd_key so we can divide/split the column into 2 new informations. So we divide and create 2 new columns
-- The first few characters are cat_id so we split it using substring in order to extract part of the string

SELECT
prd_id,
prd_key,
substring(prd_key, 1, 5) AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info ;

-- Check if we map this new cat_id into our other table i.e bronze_erp_cat_g1v2

SELECT DISTINCT id FROM bronze_erp_px_cat_g1v2 ;

-- We should also update the '-' to a '_' in the cat_id to match it to the erp file's id
SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info ;

-- Also filter out unmatched data after applying transformation

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info 
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN 
	(SELECT DISTINCT id FROM bronze_erp_px_cat_g1v2)
;

-- So we will not find CO_PE category in bronze_erp_px_cat_g1v2 table, which is fine so our check is ok

-- Extract the second part of prd_key -> using substring() also using len() to specify until where the string has to be cut.
-- using len() will make it dynamic and we are making sure that we are getting enough characters to be extracted and we will not be losing any information

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info ;

-- prd_key was extracted in order to join it with another table called the crm_sales_details table

SELECT sls_prd_key from bronze_crm_sales_details ;

-- Check this info now

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info 
WHERE SUBSTRING(prd_key, 7, LENGTH(prd_key)) IN
	(SELECT sls_prd_key from bronze_crm_sales_details )
;

SELECT sls_prd_key from bronze_crm_sales_details ;

-- Everything is fine now, just that the products are not in order which is fine

-- Next, we have name of teh product and we check if there are any unwanted spaces in it

SELECT prd_nm
FROM silver_crm_prod_info
WHERE prd_nm != TRIM(prd_nm) ;

-- Result was empty, which was expected -> Looks fine so we dont have to trim any space

-- Checking prd_cost column -> we have numbers and we can check the quality of the numbers
-- Check if we have negative numbers, negative cost or price (which is not really realistic usually, depends on business)
-- If prd_cost is NULL then make it 0 

SELECT * FROM bronze_crm_prod_info ;

SELECT prd_cost
FROM silver_crm_prod_info
WHERE prd_cost < 0 OR prd_cost = 0 OR prd_cost IS NULL ;

-- If prd_cost is NULL then make it 0 -> Use ISNULL() -> Replaces NULL values with a specified replacement value

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
prd_nm,
prd_cost,
IFNULL(prd_cost, 0) AS prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info ;

-- Check prd_line 
-- It is abbreviation of something and cardinality is low (SO checking possible values in this column)
-- Data Standardization & COnsistency

SELECT DISTINCT prd_line
FROM silver_crm_prod_info ;

-- Of course this question can be asked to the source experts as to what it was supposed to be and update accordingly.
-- For this we use CASE and then tell what is = to what 

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
prd_nm,
prd_cost,
IFNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'R' THEN 'Road'
    WHEN 'S' THEN 'Other Sales'
    WHEN 'M' THEN 'Mountain'
    WHEN 'T' THEN 'Touring'
    ELSE 'n/a'
END AS prd_line,
prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info ;

-- Check quality of start and end date of prod table

SELECT * FROM silver_crm_prod_info 
WHERE prd_end_dt < prd_start_dt
;

-- End Date must not be earlier than the start date
-- Here start is always after the end, which is not good and makes no sense


-- For such complex transformations in SQL, we can typically narrow it down to a specific set examples
-- and brainstorm multiple solution approaches

SELECT 
prd_id,
prd_key,
prd_nm,
prd_cost,
prd_cost,
prd_line,

prd_start_dt,
prd_end_dt

FROM bronze_crm_prod_info 
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')
;

-- Solutions can be tried in Excel for better picture

-- Solution 1: Switch End Date and Start Date. But there are dates overlapping.
-- Dates over lap because we compare the dates with prd_cost and it doesn't match
-- example: between 2007 - 2011 cost of a product was 12 for one record but between 2008 - 2012 of the same product, the prd_cost was 14
-- So not easy to say start is always smaller than the end date as well as the end date of the first history should be younger than the start of the next record -> this us also the rule for overlapping

-- Another issue is that some start date are not present for the products and only end dates are there. -> doesn't make sense for this but the other way(where end_date) is not there is ok

-- Solution 2: Derive the End Date from the Start Date following the rule.
-- Rule: The end of the date of the current records comes from the start date from the next record.
-- Means we take the next start date and put it at the end date for the previous records. 
-- With this it works!! The end date will be higher than the start date using this and we are making sure the end date is not overlapping with the next record -> to make it nice, we subtracted end date by 1
-- By doing this we make sure the end date is smaller than the next start date -> End date = Start Date of the 'NEXT' Record - 1
-- For the last record the end date will be 'Null' which makes sense
-- In real projects, we can validate this above solution with the source expert for clarity

-- Now we clean the start and end date with new logic
-- In SQL, if you are at specific record and you want to access another information from another record, we can use LEAD() and LAG()
-- LEAD() -> Access values from the next row within a window -> which is what we want to do

SELECT 
prd_id,
prd_key,
prd_nm,
prd_cost,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1
AS prd_end_dt_test

FROM bronze_crm_prod_info 
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')
;

-- The above didnt work cause MySQL doesn't allow direct subtraction
-- Also using DATASUB() sometimes has trouble using window functions directly inside another function like DATE_SUB() in the same expression
-- The safest approach is to calculate LEAD() in a subquery first, then apply DATE_SUB().

SELECT
    prd_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt,
    DATE_SUB(next_start_dt, INTERVAL 1 DAY) AS prd_end_dt_test
FROM (
    SELECT
        prd_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt,
        LEAD(prd_start_dt) OVER (
            PARTITION BY prd_key
            ORDER BY prd_start_dt
        ) AS next_start_dt
    FROM bronze_crm_prod_info
) t
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');


-- ADDING LEAD() in our main query


SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
prd_nm,
IFNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'R' THEN 'Road'
    WHEN 'S' THEN 'Other Sales'
    WHEN 'M' THEN 'Mountain'
    WHEN 'T' THEN 'Touring'
    ELSE 'n/a'
END AS prd_line,
prd_start_dt,
DATE_SUB(
	LEAD(prd_start_dt) OVER (
		PARTITION BY prd_key
		ORDER BY prd_start_dt
	),
    INTERVAL 1 DAY
) AS prd_end_dt

FROM bronze_crm_prod_info ;

-- Doesn't make sense to have time time in start and end date to be 00. 
-- So, we cast the start_dt and end_dt column as DATE instead of DATETIME
-- CAST (prd_start_dt AS DATE)
-- But here in MySQL we use DATE()

SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
prd_nm,
IFNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'R' THEN 'Road'
    WHEN 'S' THEN 'Other Sales'
    WHEN 'M' THEN 'Mountain'
    WHEN 'T' THEN 'Touring'
    ELSE 'n/a'
END AS prd_line,
DATE (prd_start_dt) AS prd_start_dt,
DATE(
	DATE_SUB(
		LEAD(prd_start_dt) OVER (
			PARTITION BY prd_key
			ORDER BY prd_start_dt
		),
		INTERVAL 1 DAY
	)
) AS prd_end_dt

FROM bronze_crm_prod_info ;

-- Insert this updated data into the silver table -> see Silver_CleanData file

-- Now we check quality of silver table by replacing all the bronze table names to silver table names

select * from silver_crm_prod_info;

-- next step is to clean and load crm_sales_details from bronze to silver -> We have already tested so all the bronze tables are changed to silver

select * from silver_crm_sales_details ;
select * from bronze_crm_sales_details ;
select COUNT(*) from bronze_crm_sales_details ;

-- First we have sls_od_num, which is a string so we check if it has any unwanted spaces
-- plus other fields which is a string

select * from bronze_crm_sales_details
where sls_prd_key != TRIM(sls_prd_key) ;

-- next we have cust_id which is an INT so we check if it can be a primary key 
-- i.e make sure there are not duplicates or null values
-- but we are using prd_key and cust_id with cst_id in other crm files

-- so, we check if prd_key and cst_id is working properly by doing the following

select * from bronze_crm_sales_details
where sls_prd_key NOT IN (Select prd_key FROM silver_crm_prod_info) ;

select * from silver_crm_prod_info ;

select * from bronze_crm_sales_details
where sls_cust_id NOT IN (Select cst_id FROM silver_crm_cust_info) ;

-- All clear -> so we can we can connect sales with the customers using the sls_cust_id
-- and we can connect to products using sls_prd_key and we dont have to do any transformations for it 

-- Next, we focus on date in the table, like order, shippinh and due.
-- But these dates are in INT we need to change it to DATE
-- First we check if there are any NULLs, cause negative or zero numbers can't be cast to a date

SELECT sls_order_dt FROM bronze_crm_sales_details
WHERE sls_order_dt < 0 ;


SELECT sls_order_dt FROM bronze_crm_sales_details
WHERE sls_order_dt = 0 ;

-- There are a lot of 0s. So, casting this field to DATE will be hard
-- SO we replace the 0s to NULL
-- NULL IF() -> REturns NULL if 2 given values are equal; otherwise it returns the first expression.

SELECT 
NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver_crm_sales_details
WHERE sls_order_dt = 0 ;

-- Now that we have gotten ride of 0s, we should convert it to DATE
-- Total we have 8 digits in this scenario, so the length of the date must be 8
-- If the length is less or higher than 8 then we will have issue
 
SELECT 
NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver_crm_sales_details
WHERE sls_order_dt <= 0 OR LENGTH(sls_order_dt) != 8 ;

-- There are 2 values that are less than 8, so we cant make real date with these info
-- It is bad data quality

-- We can also check the boundary -> check for outliers by validating the boundaries of the date range

SELECT 
NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze_crm_sales_details
WHERE sls_order_dt <= 0
OR LENGTH(sls_order_dt) != 8
OR sls_order_dt > 20500101 
OR sls_order_dt < 19000101    -- depending on when the usiness started
;

-- So for this datatype which was supposed to be a date, we have these issues. 
-- That there were zeros and we fixed it with null and then saw that there dates with less than the actual date size
-- and we check the dates within certain date 
-- so this the transformation for it : i.e we discard such dates as in make them NULL
-- CASE WHEN sls_oder_dt = 0 OR LENGTH(sls_order_dt)!= 8 THEN NULL
-- Next we need to convert the data from INT to DATE
-- FOr this we should first convert it into VARCHAR and then convert to DATE


SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE 
	WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt)!= 8 THEN NULL
	ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
END AS sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price

FROM bronze_crm_sales_details ;

-- Next, we can do the same for the other dates -> sls_ship_dt and sls_due_dt


SELECT sls_ship_dt FROM bronze_crm_sales_details
WHERE sls_ship_dt < 0 ;


SELECT sls_ship_dt FROM bronze_crm_sales_details
WHERE sls_ship_dt = 0 ;

-- There are no negative or zero values. Now we check for the length

SELECT sls_ship_dt FROM bronze_crm_sales_details
WHERE LENGTH(sls_ship_dt) != 8 ;

-- There is no date which has bad lenght, so we just convert this field to date
-- But we will apply the change we made the previous order date to ship date as well, just so we dont encounter this issue in later stages

SELECT 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE 
		WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
	END AS sls_order_dt,
    
    CASE 
		WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
	END AS sls_ship_dt,
    
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price

FROM bronze_crm_sales_details ;

-- Lets check for sls_due_date now:

SELECT 
NULLIF(sls_due_dt, 0) AS sls_order_dt
FROM bronze_crm_sales_details
WHERE sls_due_dt <= 0
OR LENGTH(sls_due_dt) != 8
OR sls_due_dt > 20500101 
OR sls_due_dt < 19000101    -- depending on when the usiness started
;

-- Also clean, still we will apply the same changes as before dates

SELECT 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE 
		WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
	END AS sls_order_dt,
    
    CASE 
		WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
	END AS sls_ship_dt,
    
	CASE 
		WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d')
	END AS sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price

FROM bronze_crm_sales_details ;

-- We can do another check -> 
-- Order Date must always be earlier than the Shipping Date or DUe Date
-- Cause makes no sense, when delivering without any order, so first order happens and then the shipping
-- To check invalid date orders


SELECT * FROM bronze_crm_sales_details 
WHERE sls_order_dt > sls_ship_dt
OR sls_order_dt > sls_due_dt
;

-- All clear, so the order_date is always smaller than the shipping and due date

-- Check last 3 cloumns, slaes, quantity and price. They are all related to each other.
-- We have a business rule that says, sales must be equal to QUantity * Price
-- i.e All Sales = Quantity * Price
-- And all sales, quantity and Price information should be positive numbers so it should not be zero, negative, nulls or n/a (Not Allowed)
-- So we do these checks

SELECT DISTINCT 
sls_sales,
sls_quantity,
sls_price FROM silver_crm_sales_details 
WHERE sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales,
sls_quantity,
sls_price
;

-- SO, we have wrong calculations for sales -> wrong values for sales = quantity* price, we have null values and zero values and also there is negative values
-- For quantity, the values look ok -> no negative or nulls or zero values
-- For sls_price, we have negative and zero values and NULLs
-- So we need to fix the sales and quantity
-- This cant be fixd just by ourselves, we need to ask the source experts or get information from the source system
-- We can discuss any scenarios if we have 
-- Otherwise they might say DATA Issues will be fixed directly in source system, so we will have to live with the bad data in the warehouse until the data is fixed
-- Other solution: or they can say there is no budget to fix the data. SO you either leave it ot fix the data issues in the data warehouse (but you ask the experts to support you in such system)
-- So we can create rules and different reules will give different solution

-- Our rule 1: If sales is negative, zero, or null, derive it using Quantity and Price . i.e sales = Quantity * Price
-- Our Next rule 2: If prices are zero or null, calculate it using Sales and Quantity
-- Our Rule 3: If Price is negative, convert it to a positive value

-- Building transformations


SELECT DISTINCT 
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,

CASE WHEN sls_price IS NULL OR sls_price <= 0
	 THEN sls_sales / NULLIF(sls_quantity, 0)
     ELSE sls_price
END AS sls_price,

CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	 THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
END AS sls_sales

FROM bronze_crm_sales_details 
WHERE sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales,
sls_quantity,
sls_price ;


-- The above still gave wrong calculation for sls_sales. It still had NULL or = values
-- So we used chatGPT and converted to below


SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_quantity,
    sls_price AS old_sls_price,

    -- Corrected price first
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0 THEN 
            sls_sales / NULLIF(sls_quantity,0)
        ELSE ABS(sls_price)
    END AS sls_price,

    -- Corrected sales using corrected price
    CASE
        WHEN sls_sales IS NULL 
             OR sls_sales <= 0 
             OR sls_sales != sls_quantity * 
                CASE
                    WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity,0)
                    ELSE ABS(sls_price)
                END
        THEN sls_quantity *
             CASE
                 WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity,0)
                 ELSE ABS(sls_price)
             END
        ELSE sls_sales
    END AS sls_sales

FROM bronze_crm_sales_details
WHERE sls_sales IS NULL
   OR sls_sales <= 0
   OR sls_price IS NULL
   OR sls_price <= 0
   OR sls_sales != sls_quantity * ABS(sls_price)
ORDER BY sls_sales, sls_quantity, sls_price;


-- Adding transformation to our main query

SELECT 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE 
		WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_order_dt AS CHAR), '%Y%m%d')
	END AS sls_order_dt,
    
    CASE 
		WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_ship_dt AS CHAR), '%Y%m%d')
	END AS sls_ship_dt,
    
	CASE 
		WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt)!= 8 THEN NULL
		ELSE STR_TO_DATE(CAST(sls_due_dt AS CHAR), '%Y%m%d')
	END AS sls_due_dt,
    
    CASE 
		WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
    
    CASE 
		WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END AS sls_price,

	sls_quantity

FROM bronze_crm_sales_details ;


select * FROM bronze_crm_sales_details ;


-- Insert this updated data into the silver table -> see Silver_CleanData file

-- Now we check quality of silver table by replacing all the bronze table names to silver table names in the above checks
-- Checking invalid Date orders

SELECT * FROM silver_crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt ;

-- empty, so all good

-- We didn't pass this though, so we took updated code from gpt:

SELECT DISTINCT 
sls_sales,
sls_quantity,
sls_price FROM silver_crm_sales_details 
WHERE sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales,
sls_quantity,
sls_price ; 

select * FROM silver_crm_sales_details ; 


-- Next we clean and load erp_cust_az12

select * FROM bronze_erp_cust_az12 ;

-- The customer_id ie cid in erp_cust_az12 can be connected to the crm_cust_info with its cst_key

SELECT * FROM silver_crm_cust_info ;

-- So in erp there are extra characters that is not included in crm customer info. So we remove it

select * FROM bronze_erp_cust_az12 
WHERE cid LIKE '%AW00011000%' ;


SELECT 
cid,
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
	ELSE cid
END AS cid,
bdate,
gen
FROM bronze_erp_cust_az12 ;


-- Compare it with the crm table -> 

SELECT 
cid,
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
	ELSE cid
END AS cid,
bdate,
gen
FROM bronze_erp_cust_az12 
WHERE CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
	ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM silver_crm_cust_info) ;

-- All clear, so it is cid is successfully transformed -> there is no unmatching data between crm customer info and erp_curst

-- Next, we chekc birthdate -> we can check if there is any out of range -> check for very old customers, if there are anyone older than 100 years, just for example case
-- And also to check for customer if the birthdate is in the future -> check if bdate is higher than the currect date

SELECT DISTINCT bdate FROM silver_erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > CURDATE() ;

-- So the test failed and there are many bdates that are less than 100 years ago and after the current date who are not yet born
-- This is bad data quality so we go and report it to source system. Based on the descision we will clean bdate or leave it as it is.
-- In case of cleaning bdate, we make the future dates NULL case it makes more sense to do that


SELECT 
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
	ELSE cid
END AS cid,
CASE 
	WHEN bdate > CURDATE() THEN NULL
    ELSE bdate
END AS bdate,
gen
FROM bronze_erp_cust_az12 ;

-- Next we check gender coulmn, it is low cardinality so we check all the possible values.

SELECT DISTINCT gen from silver_erp_cust_az12 ; 

-- We see that some are just abbrevations like 'M' and 'F' and also some NULL values. so we fix it with full values

SELECT DISTINCT 
    gen,
    CASE 
        WHEN gen IS NULL OR TRIM(gen) = '' THEN 'n/a'
        WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen_clean
FROM bronze_erp_cust_az12;


-- Updated query that actually works for us, here we are picking only the first character.

SELECT DISTINCT
    gen,
    CASE
        WHEN gen IS NULL OR TRIM(gen) = '' THEN 'n/a'
        WHEN LEFT(UPPER(TRIM(gen)),1) = 'F' THEN 'Female'
        WHEN LEFT(UPPER(TRIM(gen)),1) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS gen_clean
FROM bronze_erp_cust_az12;

-- Adding above to our original query

SELECT 
CASE 
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
	ELSE cid
END AS cid,
CASE 
	WHEN bdate > CURDATE() THEN NULL
    ELSE bdate
END AS bdate,
CASE
        WHEN gen IS NULL OR TRIM(gen) = '' THEN 'n/a'
        WHEN LEFT(UPPER(TRIM(gen)),1) = 'F' THEN 'Female'
        WHEN LEFT(UPPER(TRIM(gen)),1) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM bronze_erp_cust_az12 ;


-- Now we can insert the above in the silver layer
-- Testing the above in silver tables

-- Next we clean and load erp_loc_a101

SELECT * FROM bronze_erp_loc_a101 ;

-- Here we have cid and country fields
-- We can connect the cid from erp_loc file to crm_cust_info's cst_key

SELECT * FROM silver_crm_cust_info ;

-- But the cid in erp_loc has an additional '-' in its key. SO we need to remove it

SELECT 
cid,
REPLACE(cid, '-', '') AS cid,
cntry
FROM bronze_erp_loc_a101 ;

-- The '-' is fixed now
-- We can test to see if we have any unmatching data from our crm customer info and erp_loc tables


SELECT 
REPLACE(cid, '-', '') AS cid,
cntry
FROM bronze_erp_loc_a101 
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver_crm_cust_info)
;

-- Result was empty -> So, we fixed cid and there are no unmatched data between the cst_key in crm and cid in erp files

-- Next we check for country field in erp_loc
-- Check for low cardinality  and check all possible values in it

-- Data Standardization & COnsistency

SELECT DISTINCT cntry
FROM silver_erp_loc_a101 
ORDER By cntry ;

-- The result shows many empty and null values, and abbreviations of countries so it is a mix.
-- US and USA and United States, DE and Germany etc
-- So many values that don't match properly and we should clean it


SELECT DISTINCT

CASE 
		WHEN (TRIM(cntry)) = 'DE' THEN 'GERMANY' 
		WHEN (TRIM(cntry)) IN ('US', 'USA') THEN 'United States' 
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
    ELSE TRIM(cntry)
END AS cntry_new,
cntry
FROM bronze_erp_loc_a101 ;


-- Check if the cntry field has any whitespaces cause the above query didnt work for our data in MySQL

SELECT DISTINCT 
cntry,
CONCAT('|', cntry, '|') AS visible,
LENGTH(cntry)
FROM bronze_erp_loc_a101;

-- We have to use this cause we have unwanted white spaces in our data cause we use MySQL which is not detected in SQL Server

SELECT DISTINCT
CASE 
    WHEN (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', ''))) = 'DE' 
        THEN 'Germany'
    WHEN (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', ''))) IN ('US','USA') 
        THEN 'United States'
    WHEN cntry IS NULL OR TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', '')) = '' 
        THEN 'n/a'
    ELSE (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', '')))
END AS new_cntry,

cntry

FROM bronze_erp_loc_a101;

-- Now we add the above to our transformation query

SELECT 
REPLACE(cid, '-', '') AS cid,															-- Handled invalid values -> replaced '-' for nothing to match the cst_key in crm_cust_info table
CASE 
    WHEN (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', ''))) = 'DE' 
        THEN 'Germany'
    WHEN (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', ''))) IN ('US','USA') 
        THEN 'United States'
    WHEN cntry IS NULL OR TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', '')) = '' 
        THEN 'n/a'
    ELSE (TRIM(REPLACE(REPLACE(cntry, '\r', ''), '\n', '')))
END AS cntry																		    -- Normalized and Handled missing or blank country code -> we also did extra triming because of whitespaces

FROM bronze_erp_loc_a101 ;


-- Now we can add the above transformation query to our silver table (taking the cleaned query and loading to the silver table)

-- Next we do quality test above of the silver_erp_loc table

SELECT * FROM silver_erp_loc_a101 ;

-- Now we clean the last table -> epr_px_cat_g1v2

SELECT * FROM bronze_erp_px_cat_g1v2 ;

-- 'id' in erp table can be connected to the prod_info in crm table -> cat_id
-- SO we need to make sure it is in the correct format

SELECT * FROM silver_crm_prod_info ;

-- cat_id in crm is already test and it matches the id in erp table so we can use it without any changes

-- Next one 'cat' field is a string and we check the following
-- Check for unwanted spaces in both 'cat' and 'subcat' and 'maintenance' fields

SELECT cat FROM bronze_erp_px_cat_g1v2
WHERE cat != TRIM(cat) ;

SELECT subcat FROM bronze_erp_px_cat_g1v2
WHERE subcat != TRIM(subcat) ;

SELECT maintenance FROM bronze_erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance) ; 

-- Result showed no unwanted spaces. SO we are clear. 

-- Next is to Check Data Standardization & Normalization. Because all those fields have low cardinality

SELECT DISTINCT cat FROM bronze_erp_px_cat_g1v2 ; 

SELECT DISTINCT subcat FROM bronze_erp_px_cat_g1v2 ; 

-- All values in these fields were friendly and nice


SELECT DISTINCT maintenance FROM bronze_erp_px_cat_g1v2 ; 

-- We found some values that was not in the SQL Server. SO we dig deeper

SELECT DISTINCT maintenance, LENGTH(maintenance) AS len
FROM bronze_erp_px_cat_g1v2;

-- So we have a YES with 4 length and the other Yes with 3 lenght

-- We can trim and check maybe

SELECT DISTINCT TRIM(maintenance), LENGTH(maintenance) AS len
FROM bronze_erp_px_cat_g1v2;

SELECT DISTINCT 
TRIM(REPLACE(REPLACE(maintenance, '\r', ''), '\n', '')) AS maintenance
FROM bronze_erp_px_cat_g1v2;

-- Add the above to our actual query and insert it into the silver table
-- Transformed data for erp_px table is the below which will be added to silver table in SIlver_CleanData file

SELECT * FROM bronze_erp_px_cat_g1v2 ;

SELECT 
id,
cat,
subcat,
TRIM(REPLACE(REPLACE(maintenance, '\r', ''), '\n', '')) AS maintenance
FROM bronze_erp_px_cat_g1v2 ;

SELECT * FROM silver_erp_px_cat_g1v2 ;
SELECT COUNT(*) FROM silver_erp_px_cat_g1v2 ;

-- Other queries used in cleanData file

SELECT * FROM silver_erp_px_cat_g1v2 ;
SELECT COUNT(*) FROM silver_erp_px_cat_g1v2 ;


SELECT * FROM silver_erp_loc_a101 ;

SELECT * FROM silver_erp_cust_az12 ;
SELECT * FROM silver_erp_loc_a101 ;

SELECT * FROM silver_erp_cust_az12 ;

select * from silver_crm_sales_details;
select COUNT(*) from bronze_crm_sales_details;
select COUNT(*) from silver_crm_sales_details;

select * from silver_crm_prod_info;
select COUNT(*) from bronze_crm_prod_info;
select COUNT(*) from silver_crm_prod_info;

select * from silver_crm_sales_details;
select COUNT(*) from bronze_crm_sales_details;
select COUNT(*) from silver_crm_sales_details;

select * from silver_crm_cust_info;

