-- Building Gold layer
-- Here we are building the business objects like CUTOMER, PRODUCT, and SALES
-- And then we try to connect the ones that has relationships between then
-- i.e from crm to erp and within the crm

-- First we build the CUSTOMER object (dimension) in crm_cust_info table
-- Using silver tables cause they are cleaned and transformed qnd ready to use

SELECT * FROM silver_crm_cust_info;

-- Select the columns we need in Gold layer form the above
-- No meta data info, cause it only belongs in silver layer
-- we will also add alias like ci, so we can use it to later connect to other tables

SELECT 
	ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gndr,
    ci.cst_create_date
FROM silver_crm_cust_info ci;

-- Connect erp and crm via the cid in erp _cust table and cst_key from the crm_cust table
-- Because they belong to CUSTOMER object
-- SO we should join the tables
-- We will avoid using inner join 
-- cause if other table doesn't have all the information about the customers, we might end up losing the customers
-- Our strategy: is to always start with the master table
-- Master table concept is different in SQL Server
-- Here in MySQL, In Bronze → Silver → Gold architecture, a “master table” usually means the cleaned dimension table.
-- eg: bronze_crm_cust_info is the raw data
-- silver_crm_cust_info is the cleaned data
-- dim_customer will be the master table 


-- Lets do left join from master table

SELECT 
	ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gndr,
    ci.cst_create_date,
    
    ca. bdate,
    ca.gen,
    
    la.cntry
    
FROM silver_crm_cust_info ci

LEFT JOIN silver_erp_cust_az12 ca
ON 		  ci.cst_key = ca.cid

LEFT JOIN silver_erp_loc_a101 la
ON		  ci.cst_key = la.cid ;

-- After Joining tables, we have to check if any duplicates were introduced by the join logic

SELECT cst_id, COUNT(*) FROM 
(	SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		
		ca. bdate,
		ca.gen,
		
		la.cntry
		
	FROM silver_crm_cust_info ci

	LEFT JOIN silver_erp_cust_az12 ca
	ON 		  ci.cst_key = ca.cid

	LEFT JOIN silver_erp_loc_a101 la
	ON		  ci.cst_key = la.cid
)t GROUP BY cst_id
HAVING COUNT(*) > 1 ;

-- No duplicates -> that means, after joining all those tables with the customer info, those tables didnt cause any issues and it didnt duplicate our data
-- So we dont have to worry about the duplicates
-- In our join query, we have an issue with intgration, we have two tables giving the gender info -> 1. cst_gndr and gen
-- So we do DATA INTEGRATION

SELECT DISTINCT
    ci.cst_gndr,
    ca.gen

FROM silver_crm_cust_info ci

LEFT JOIN silver_erp_cust_az12 ca
ON 		  ci.cst_key = ca.cid

LEFT JOIN silver_erp_loc_a101 la
ON		  ci.cst_key = la.cid 
 
ORDER BY 1, 2 ;

-- NULLs often comes from joined tables! 
-- NULL will appear if SQL finds no match

-- We see in result that cst_gndr and gen dont match
-- In such case we need to ask the source experts: which source is the master for these values?
-- If they say the master source of the Customer Data is CRM, we choose what is in CRM to match the data.
-- Example, if in CRM there is Female and the same data is Male in ERP then we consider the CRM and say it is a Male
-- Our Rule 1: If we have data in the gender information in CRM(the master) then we use that 
-- Our Rule 2: 


SELECT DISTINCT
    ci.cst_gndr,
    ca.gen,
    
    CASE 
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr     -- CRM is the master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen
FROM silver_crm_cust_info ci

LEFT JOIN silver_erp_cust_az12 ca
ON 		  ci.cst_key = ca.cid

LEFT JOIN silver_erp_loc_a101 la
ON		  ci.cst_key = la.cid 
 
ORDER BY 1, 2 ;

-- Now we apply the above query in our main one

SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		CASE 
			WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr     -- CRM is the master for gender info
			ELSE COALESCE(ca.gen, 'n/a')
		END AS new_gen,
		ci.cst_create_date,
		
		ca. bdate,
		
		
		la.cntry
		
	FROM silver_crm_cust_info ci

	LEFT JOIN silver_erp_cust_az12 ca
	ON 		  ci.cst_key = ca.cid

	LEFT JOIN silver_erp_loc_a101 la
	ON		  ci.cst_key = la.cid ;


-- Rename coulmns to friends, meaningful names -> using our naming convention -> snake_case

SELECT 
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		ci.cst_marital_status AS marital_status,
		CASE 
			WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr     -- CRM is the master for gender info
			ELSE COALESCE(ca.gen, 'n/a')
		END AS gender,
        
		ci.cst_create_date AS create_date,
		ca. bdate AS birthdate,
		la.cntry AS country
		
	FROM silver_crm_cust_info ci

	LEFT JOIN silver_erp_cust_az12 ca
	ON 		  ci.cst_key = ca.cid

	LEFT JOIN silver_erp_loc_a101 la
	ON		  ci.cst_key = la.cid ;
    
-- Next, we can also sort the columns into logical groups to improve readability
-- So we are just rearranging the fields in the above query
-- completed query looks like the below

SELECT 
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
        la.cntry AS country,
		ci.cst_marital_status AS marital_status,
		CASE 
			WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr     -- CRM is the master for gender info
			ELSE COALESCE(ca.gen, 'n/a')
		END AS gender,
        ca. bdate AS birthdate,
		ci.cst_create_date AS create_date
		
	FROM silver_crm_cust_info ci

	LEFT JOIN silver_erp_cust_az12 ca
	ON 		  ci.cst_key = ca.cid

	LEFT JOIN silver_erp_loc_a101 la
	ON		  ci.cst_key = la.cid ;


-- Now important question to answer: Is it a fact table or a dimension table?
-- Dimensions hold descriptive information about objects 
-- the above table has information like, IDs, Dates & numbers which are describing information about customers
-- So it is a dimension table
-- For dimension we always need Primary_Key so we can depend on the source system for this
-- In this table it is clear, but in some tables it is not so in that case we will have to create t by ourselves
-- Those keys are called as surrogate keys: System-generated unique identifier assigned to each record in a table
-- Oh, we dont have it in our table so we create it by ourselves using the window function -> ROW_NUMBER()


SELECT 
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		ci.cst_marital_status AS marital_status,
		CASE 
			WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr     -- CRM is the master for gender info
			ELSE COALESCE(ca.gen, 'n/a')
		END AS gender,
        
		ci.cst_create_date AS create_date,
		ca. bdate AS birthdate,
		la.cntry AS country
		
	FROM silver_crm_cust_info ci

	LEFT JOIN silver_erp_cust_az12 ca
	ON 		  ci.cst_key = ca.cid

	LEFT JOIN silver_erp_loc_a101 la
	ON		  ci.cst_key = la.cid ;
    
-- Next, we can also sort the columns into logical groups to improve readability
-- So we are just rearranging the fields in the above query
-- completed query looks like the below

SELECT 
		ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
        la.cntry AS country,
		ci.cst_marital_status AS marital_status,
		CASE 
			WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr     -- CRM is the master for gender info
			ELSE COALESCE(ca.gen, 'n/a')
		END AS gender,
        ca. bdate AS birthdate,
		ci.cst_create_date AS create_date
		
	FROM silver_crm_cust_info ci

	LEFT JOIN silver_erp_cust_az12 ca
	ON 		  ci.cst_key = ca.cid

	LEFT JOIN silver_erp_loc_a101 la
	ON		  ci.cst_key = la.cid ;
    
    
-- Now we can create the CUSTOMER object (dimension)
-- NOTE: All the object in the gold layer is to be created by VIEW not table -> Check GoldLayer file
    
-- Test -> to check the quality of this result

SELECT * FROM gold_dim_customers ;

-- Check gender first cause that is the change we made

SELECT DISTINCT gender FROM gold_dim_customers ;

-- All good,

-- Next, we create the PRODUCT object 

-- Product info is available in both CRM and ERP systems -> First we will check the crm table and then join it with erp 
-- Product objects from CRM contains historic as well as current informations
-- Depending on the requirement we will do analysis on the either historic or current information, in general
-- We are going to use only current current data for analysis, so we filter out the historical data
-- Our rule for this: If End_Date is NULL then we consider it is Current Info of the Product!

SELECT * FROM silver_crm_prod_info pn ;

SELECT 
	pn.prd_id,
    pn.cat_id,
    pn.prd_key, 
    pn.prd_nm,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt
FROM silver_crm_prod_info pn
WHERE prd_end_dt is NULL	 ;				-- Filter out all historical data

-- Next we will go and connect the prd_key in CRM to id in ERP system
-- Master information is the CRM and everything else is secondary
-- SO we use Left Join to make sure we do not loose any data/ filtering any data

SELECT 
	pn.prd_id,
    pn.cat_id,
    pn.prd_key, 
    pn.prd_nm,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt,
    
    pc.cat,
    pc.subcat,
    pc.maintenance
FROM silver_crm_prod_info pn
LEFT JOIN silver_erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt is NULL ;

-- Next, we check the quality of this result
-- Important -> To check the uniqueness -> to chekc the prd_key is unique (cause we use it layer to join it with sales)

SELECT prd_key, COUNT(*) FROM(
SELECT 
	pn.prd_id,
    pn.cat_id,
    pn.prd_key, 
    pn.prd_nm,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt,
    
    pc.cat,
    pc.subcat,
    pc.maintenance
FROM silver_crm_prod_info pn
LEFT JOIN silver_erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt is NULL
) t GROUP BY prd_key
HAVING COUNT(*) > 1 ;

-- All clean so no duplicates of prd_key
-- silver_erp_px_cat_g1v2 didn't create any duplicate for our join
-- Each product is only one record
-- Next we chekc if we have any same field twice -> we dont so next

-- Next we sort the columns into logical groups to improve redability
-- And rename columns to friendly, meaningful names

SELECT 
	pn.prd_id AS product_id,
    pn.prd_key AS product_number, 
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS product_cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date

FROM silver_crm_prod_info pn
LEFT JOIN silver_erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt is NULL ;


-- To decide if we have fact or dimension
-- We have a lot of description of a product ie. its name, category, cost etc --> So PRODUCT object is a DIMENSION
-- Each row descibes one product so, PRODUCT table is a dimension

-- SO , we create a primary key for it -> this case, a surrogate key using ROW_NUMBER()

SELECT 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
    pn.prd_key AS product_number, 
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS product_cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date

FROM silver_crm_prod_info pn
LEFT JOIN silver_erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt is NULL ;

-- Next we create a VIEW for this -> Go to Gold Layer

SELECT * FROM gold_dim_products ;


-- Next, we create FACT SALES object

-- For sales, we have data only from CRM and nothing from ERP

SELECT * FROM silver_crm_sales_details sd ;

SELECT
	sd.sls_ord_num,
    sd.sls_prd_key,
    sd.sls_cust_id,
    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price
FROM silver_crm_sales_details sd ;

-- No integration or anything but answering one question -> Is sales object a dimension or a fact table?
-- By looking at the sales details, we can see transactions, events
-- We have a lot of date informations and well as a lot of measures and metrics as well as a lot of ids connecting multiple dimensions
-- SO SALES object is a FACT

-- Since fact connects multiple dimensions, we should connect the surragate keys to these dimensions since they are coming form them
-- So the prd_key and cust_id comes from the source system
-- We connect our data model using the surrogate keys
-- Our Rule for Building FACT -> Use the dimension's surrogate keys instead of IDs to easily connect facts wth dimensions
-- We will join the two dimensions in order to get the surrogate key key prd_key and cust_id
-- This is called as Data Look up -> we are joining the tables only to get one information
-- Using left join to not loose any transaction
-- First we join with prd_key
-- Silver layer doesn't have any surrogate keys, we created them in the GOlD layer
-- So for our fact table here we will be joining the silver layer with the gold layer
-- Same for customer_id

SELECT
	sd.sls_ord_num,
    pr.product_key,							-- Dimension Key from gold layer
    cu.customer_key,						-- Dimension Key from gold layer
    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price
FROM silver_crm_sales_details sd 
LEFT JOIN gold_dim_products pr				
ON sd.sls_prd_key = pr.product_number		-- Joining product key (dimension) from gold layer
LEFT JOIN gold_dim_customers cu
ON sd.sls_cust_id = cu.customer_id			-- Joining customer key (dimension) from gold layer
;

-- So now from fact table, we have 2 keys from dimension
-- This will help us to connect the data model from facts to dimensions
-- this was an important step -> building fact table -> putting the surrogate keys from the dimension tables in the fact table
-- Next is to give friendly names

 
SELECT
	sd.sls_ord_num AS order_number,
    pr.product_key,							
    cu.customer_key,						
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver_crm_sales_details sd 
LEFT JOIN gold_dim_products pr				
ON sd.sls_prd_key = pr.product_number		
LEFT JOIN gold_dim_customers cu
ON sd.sls_cust_id = cu.customer_id	;

-- Next we sort the columns into logical groups to improve readability
-- It will be in this order -> Dimension keys, Dates and then Measures (clearly a fact)
-- Next we will build it using VIEW -> check gold layer for this 


-- Next, we check the quality of Gold table

SELECT * FROM gold_fact_sales ; 				-- Foreign Key Integrity (Dimensions)

-- Next, fact check -> Check if all dimension tables can sucessfully join to the fact table
-- 1. Check if facts are connecting to the customer dimension


SELECT * FROM gold_fact_sales f
LEFT JOIN gold_dim_customers c
ON c.customer_key = f.customer_key
WHERE c.customer_key IS NULL ;


-- All clear, so the test was sucesssfully passsed

-- Next we do the same thing with the products table -> 2. Check if facts are connecting to the product dimension


SELECT * FROM gold_fact_sales f
LEFT JOIN gold_dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold_dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL ;

-- All clear, the results was empty, no duplicates
-- Therefore, we can clarify that the sales (fact) is sucessfully connected to its customers and products (dimesions)




