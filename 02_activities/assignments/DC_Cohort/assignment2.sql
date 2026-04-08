/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1

SELECT 
	product_name || ', ' || 		-- keeps the product name the same
	COALESCE(product_size, '')|| 	-- replaces NULL in product_size with a blank ''
	' (' || COALESCE(product_qty_type, 'unit') || ')' -- replaces NULL in product_qty_type with 'unit'
	as Product_List  				-- changes name of list to Product_list
FROM product;


--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2


SELECT * FROM (
	SELECT 
		*, 
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY market_date ASC)
		AS customer_visits
	FROM customer_purchases 
	WHERE market_date < '2022-04-29' 
	) AS x;

--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3

SELECT * FROM (
	SELECT
		*, 
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY market_date DESC, transaction_time DESC)
		AS customer_visits
	FROM customer_purchases 
	) AS x
WHERE x.customer_visits = 1;

--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY within the PARTITION BY if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4

SELECT
	*
	,COUNT(product_id) OVER( 
	PARTITION BY customer_id, product_id) 
	AS times_product_in_order 
	-- this shows the number of orders that the product was included in an order, but not the actual amount that was purchased. 
	-- It does show different prices of the product id
	,SUM(quantity) OVER( 
	PARTITION BY customer_id, product_id) 
	AS total_quantity_of_product_purchased 
	-- this shows the actual amount purchased for each customer 
	-- it does not show if the product was different price each time, just the total number that the customer purchased
FROM customer_purchases
WHERE market_date < '2022-04-29'
ORDER BY total_quantity_of_product_purchased DESC; -- shows us the customer who bought the most; 


--END QUERY


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5

SELECT product_name,
	CASE
		WHEN INSTR(product_name, '-')>0 -- only performs the substr on words with - in it
			THEN RTRIM(LTRIM(SUBSTR(product_name,instr(product_name, '-')+1))) -- extracts text beyond first - and trims blank spaces
		ELSE NULL -- fills in rest as NULL
	END AS description -- names the column description 
FROM product;


--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6

SELECT product_name,
	CASE
		WHEN INSTR(product_name, '-')>0 -- only performs the substr on words with - in it
			THEN TRIM(SUBSTR(product_name,instr(product_name, '-')+1)) -- extracts text beyond first - and trims blank spaces
		ELSE NULL -- fills in rest as NULL
	END AS description -- names the column description 
FROM product

WHERE product_size REGEXP '\d';


--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7

--------- 1. Create first temp table with total sales and each day
--- remove table if it exists to start fresh
DROP TABLE IF EXISTS temp.new_customer_purchases;

--- create table
CREATE TABLE temp.new_customer_purchases AS

--- defintion of table
SELECT *,
	SUM(quantity * cost_to_customer_per_qty) AS total_sales
FROM customer_purchases
GROUP BY market_date; 

--------- 2. Create QUERY the table for top and bottom 

DROP TABLE IF EXISTS temp.top_table;

--- create table
CREATE TABLE temp.top_table AS

--- query table for top
SELECT
	market_date,
	total_sales,
	'best' AS day
FROM temp.new_customer_purchases
ORDER BY total_sales DESC
LIMIT 1;


--- query table for bottom
DROP TABLE IF EXISTS temp.bottom_table;

--- create table
CREATE TABLE temp.bottom_table AS
SELECT
	market_date,
	total_sales,
	'worst' AS day
FROM temp.new_customer_purchases
ORDER BY total_sales ASC
LIMIT 1;	


--- combine them together 
SELECT *
FROM top_table 
UNION -- combines them 
SELECT * 
FROM bottom_table;

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--QUERY 8

--- find total number of customers 
DROP TABLE IF EXISTS temp.num_of_customers;

CREATE TABLE temp.num_of_customters AS
	SELECT
	count(customer_id)
	FROM customer; 
-- should return 26 customers 

--- find total number of unique products per vendor 
DROP TABLE IF EXISTS temp.unique_products_per_vendor;

CREATE TABLE temp.unique_products_per_vendor AS
SELECT DISTINCT
    v.vendor_name,
    p.product_name,
    vi.original_price,
	5 AS quantity_per_customer
FROM vendor_inventory AS vi
JOIN vendor AS v 
    ON vi.vendor_id = v.vendor_id
JOIN product AS p 
    ON vi.product_id = p.product_id
ORDER BY v.vendor_name, p.product_name; -- should return 3 vendors, with 8 items (3, 1, 4 distinct products each) 

--- now cross join the customers 




/*
y= 26 distinct customers 
x1= each unique vendor has #unique_products at $price = list of unique products and their prices
x2 = x1 * 5 =  amount of product for each vendor's inventory to be sold to each customer
z = 26 customers * total amount that each customer would spend if they buy 5 of everything from every vendor'

*/


--END QUERY

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
--QUERY 9




--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
--QUERY 10




--END QUERY


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
--QUERY 11




--END QUERY


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */
--QUERY 12




--END QUERY



