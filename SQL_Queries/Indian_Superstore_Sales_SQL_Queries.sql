CREATE TABLE raw_sales (
      customer_id VARCHAR(20),
      customer_name VARCHAR(100),
      date_of_birth DATE,
      sales NUMERIC,
      year INT,
      outlet_type VARCHAR(50),
      city_type VARCHAR(50),
      category_of_goods VARCHAR(100),
      region VARCHAR(50),
      country VARCHAR(50),
      segment VARCHAR(50),
      sales_date DATE,
      order_id VARCHAR(30),
      order_date DATE,
      ship_date DATE,
      ship_mode VARCHAR(50),
      state VARCHAR(100),
      postal_code VARCHAR(20),
      product_id VARCHAR(30),
      sub_category VARCHAR(100),
      product_name VARCHAR(250),
      quantity INT,
      discount NUMERIC,
      profit NUMERIC
)

--data cleaning
SELECT * FROM raw_sales
LIMIT 10;

--rows count
SELECT COUNT(*) 
FROM raw_sales;

--Checking NULL Values
SELECT * FROM raw_sales
WHERE customer_id IS NULL
OR 
customer_name IS NULL
OR 
date_of_birth IS NULL
OR
sales IS NULL
OR
year IS NULL
OR
outlet_type IS NULL
OR
city_type IS NULL
OR 
category_of_goods IS NULL
OR
region IS NULL
OR
country IS NULL
OR
segment IS NULL
OR
sales_date IS NULL
OR
order_id IS NULL
OR
order_date IS NULL
OR 
ship_date IS NULL
OR 
ship_mode IS NULL
OR 
state IS NULL
OR
postal_code IS NULL 
OR
product_id IS NULL
OR
sub_category IS NULL
OR
product_name IS NULL
OR
quantity IS NULL
OR
discount IS NULL
OR
profit IS NULL;


--Database Design (Normalization)
--Customers Table
CREATE TABLE customers AS
SELECT DISTINCT 
     customer_id,
	 customer_name,
	 date_of_birth,
	 segment
FROM raw_sales;

SELECT * FROM customers
LIMIT 10;

SELECT COUNT(*) 
FROM customers;

--Products Table
CREATE TABLE products AS 
SELECT DISTINCT
     product_id,
	 product_name,
	 category_of_goods,
	 sub_category
FROM raw_sales;

SELECT * FROM products
LIMIT 10;

SELECT COUNT(*)
FROM products;

--Location Table
CREATE TABLE locations AS
SELECT DISTINCT 
       region,
       country,
	   state,
	   city_type,
	   postal_code
FROM raw_sales;

--Add location_id to location table
ALTER TABLE locations
ADD COLUMN location_id SERIAL;

--Add KEY to column
ALTER TABLE locations
ADD PRIMARY KEY (location_id);

SELECT * FROM locations
LIMIT 10;

SELECT COUNT(*)
FROM locations

--Orders Table
CREATE TABLE orders AS
SELECT DISTINCT
        order_id,
        customer_id,
		order_date,
		sales_date,
		ship_date,
		ship_mode,
		outlet_type,
		year,
		region,
		country,
		state, 
		city_type,
		postal_code
FROM raw_sales;

--Add location_id to orders table
ALTER TABLE orders
ADD COLUMN location_id INT;

--populate location_id
UPDATE orders o
SET location_id = l.location_id
FROM locations l
WHERE o.region = l.region
AND o.country = l.country
AND o.state = l.state
AND o.city_type = l.city_type
AND o.postal_code = l.postal_code;

--remove duplicate location columns in orders table
ALTER TABLE orders
DROP COLUMN region,
DROP COLUMN country,
DROP COLUMN state,
DROP COLUMN city_type,
DROP COLUMN postal_code;

SELECT * FROM orders
LIMIT 10;

SELECT COUNT(*)
FROM orders;

--Sales Table
CREATE TABLE sales AS
SELECT
    customer_id,
    order_id,
	product_id,
	sales,
	quantity,
	discount,
	profit
FROM raw_sales;

--Add sale_id to sales table
ALTER TABLE sales
ADD COLUMN sale_id SERIAL PRIMARY KEY;

SELECT * FROM sales
LIMIT 10;

SELECT COUNT(*) 
FROM sales;

--Now before adding keys, let's verify the data model.
--Check 1: Is customer_id unique?
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id 
HAVING COUNT(*) > 1;

--Check 2: Is product_id unique?
SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

--Check 3: Is order_id unique?
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

--next, check the locations
SELECT COUNT(*)
FROM locations;

SELECT COUNT(DISTINCT (region, country, state, city_type, postal_code))
FROM raw_sales;

--Now Add Keys on tables
--First Primary Keys
--Customers Table
ALTER TABLE customers
ADD PRIMARY KEY (customer_id);

--Products Table
ALTER TABLE products
ADD PRIMARY KEY (product_id);

--Orders Table
ALTER TABLE orders
ADD PRIMARY KEY (order_id);

--Add Foreign Keys
--orders -> customers
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

--orders -> locations
ALTER TABLE orders
ADD CONSTRAINT fk_orders_location
FOREIGN KEY (location_id)
REFERENCES locations(location_id);

--sales -> customers
ALTER TABLE sales
ADD CONSTRAINT fk_sales_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

--sales -> orders
ALTER TABLE sales
ADD CONSTRAINT fk_sales_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

--sales -> products
ALTER TABLE sales
ADD CONSTRAINT fk_sales_product
FOREIGN KEY (product_id)
REFERENCES Products(product_id);

--create indexes
CREATE INDEX idx_customer ON
orders(customer_id);

CREATE INDEX idx_product ON
sales(product_id);

CREATE INDEX idx_order ON
sales(order_id);

CREATE INDEX idx_sales_customer ON
sales(customer_id);

CREATE INDEX idx_state ON
locations(state);

CREATE INDEX idx_region ON
locations(region);

--test the relationships
SELECT
    o.order_id,
    c.customer_name,
    p.product_name,
    s.sales,
    s.profit,
    l.state,
    l.region
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN sales s
    ON o.order_id = s.order_id
JOIN products p
    ON s.product_id = p.product_id
JOIN locations l
    ON o.location_id = l.location_id
LIMIT 10;

--Phase 1: Exploratory Data Analysis (EDA)
--1.total sales revenue
SELECT SUM(sales) AS total_revenue
FROM sales;

--2.total profit
SELECT SUM(profit) AS total_profit
FROM sales;

--3.total orders
SELECT COUNT(*) AS total_orders
FROM orders;

--4.total customers
SELECT COUNT(*) AS total_customers
FROM customers;

--5.total products
SELECT COUNT(*) AS total_products
FROM products;

--6.average sales
SELECT ROUND(AVG(sales),2) AS avg_sales
FROM sales;

--7.highest sale
SELECT MAX(sales) AS highest_sales
FROM sales;

--8.lowest sale
SELECT MIN(sales) AS lowest_sales
FROM sales;

--9.average profit
SELECT ROUND(AVG(profit),2) AS avg_profit
FROM sales;

--10.average discount
SELECT ROUND(AVG(discount),2) AS avg_discount
FROM sales;

--Category Analysis
--1.sales by category
SELECT p.category_of_goods,
       SUM(s.sales) AS total_sales
FROM sales s
JOIN products p 
     ON s.product_id = p.product_id
GROUP BY p.category_of_goods
ORDER BY total_sales DESC;

--2.profit by category
SELECT p.category_of_goods, 
       SUM(s.profit) AS total_profit
FROM sales s
JOIN products p 
     ON s.product_id = p.product_id
GROUP BY p.category_of_goods
ORDER BY total_profit DESC;

--3.number of products in each category
SELECT category_of_goods, 
       COUNT(*) AS total_products
FROM products
GROUP BY category_of_goods
ORDER BY total_products DESC;

--Location Analysis
--1.revenue by region
SELECT l.region, 
       SUM(s.sales) AS revenue
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l
     ON o.location_id = l.location_id
GROUP BY l.region
ORDER BY revenue DESC;

--2.profit by state
SELECT l.state, 
       SUM(s.profit) AS total_profit
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l
     ON o.location_id = l.location_id
GROUP BY l.state
ORDER BY total_profit DESC;

--3.revenue by outlet type
SELECT o.outlet_type, 
       SUM(s.sales) AS revenue
FROM sales s
JOIN orders o
    ON s.order_id = o.order_id
GROUP BY o.outlet_type 
ORDER BY revenue DESC;

--4.revenue by ship mode
SELECT o.ship_mode, 
       SUM(s.sales) AS revenue
FROM sales s
JOIN orders o
    ON s.order_id = o.order_id
GROUP BY o.ship_mode
ORDER BY revenue DESC;

--5.monthly sales trend
SELECT 
     EXTRACT(MONTH FROM order_date) AS month,
	 SUM(s.sales) AS revenue
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY month
ORDER BY month;

--Business Analysis
--1.top 10 products by sales
SELECT p.product_name, 
       SUM(s.sales) AS total_sales
FROM sales s
JOIN products p 
     ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 10;

--2.top 10 products by profit
SELECT p.product_name, 
       SUM(s.profit) AS total_profit
FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC
LIMIT 10;

--3.products generated least profit
SELECT p.product_name,
       SUM(s.profit) AS total_profit
FROM sales s
JOIN products p 
    ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit
LIMIT 10;

--4.product categories generated highest revenue
SELECT p.category_of_goods, 
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN products p 
     ON s.product_id = p.product_id
GROUP BY p.category_of_goods
ORDER BY total_revenue DESC;

--5.sub-category generated highest profit
SELECT p.sub_category,
       SUM(s.profit) AS total_profit
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.sub_category
ORDER BY total_profit DESC
LIMIT 1;

--6.sub-category highest average discout
SELECT p.sub_category, 
       ROUND(AVG(s.discount),2) AS avg_discount
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.sub_category
ORDER BY avg_discount DESC
LIMIT 1;

--Customer Analysis
--1.customers by segment
SELECT segment,
       COUNT(*) AS total_customers
FROM customers
GROUP BY segment
ORDER BY total_customers DESC;
       
--2.revenue by customer segment
SELECT c.segment, 
       SUM(s.sales) AS revenue
FROM customers c
JOIN sales s
     ON c.customer_id = s.customer_id
GROUP BY c.segment
ORDER BY revenue DESC;

--3.top 10 customers by sales
SELECT c.customer_name, 
       SUM(s.sales) AS total_sales
FROM sales s
JOIN customers c
     ON s.customer_id = c.customer_id 
GROUP BY c.customer_name
ORDER BY total_sales DESC
LIMIT 10;

--4.top 10 customers by profit
SELECT c.customer_name, 
       SUM(s.profit) AS total_profit
FROM sales s
JOIN customers c
     ON s.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_profit DESC
LIMIT 10;

--5.customer segment generates highest revenue
SELECT c.segment, 
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN customers c 
     ON s.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC
LIMIT 1;

--6.customers placed most orders
SELECT c.customer_name, 
       COUNT(DISTINCT s.order_id) AS total_orders
FROM sales s
JOIN customers c
   ON s.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_orders DESC
LIMIT 10;

--7.customers never generated profit
SELECT c.customer_name,
       SUM(s.profit) AS overall_profit
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
GROUP BY c.customer_name
HAVING SUM(s.profit) <= 0
ORDER BY overall_profit ASC;

--Regional Analysis
--1.region with highest profit margin
SELECT 
    l.region,
    SUM(s.profit) AS total_profit,
    SUM(s.sales) AS total_sales,
    ROUND(
        SUM(s.profit) * 100.0 / NULLIF(SUM(s.sales), 0),
        2
    ) AS profit_margin
FROM sales s
JOIN orders o
    ON s.order_id = o.order_id
JOIN locations l
    ON o.location_id = l.location_id
GROUP BY l.region
ORDER BY profit_margin DESC
LIMIT 1;

--2.state generated the highest sales
SELECT l.state, 
       SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
    ON s.order_id = o.order_id
JOIN locations l
    ON o.location_id = l.location_id
GROUP BY l.state
ORDER BY total_sales DESC
LIMIT 1;

--3.state generated the highest profit
SELECT l.state, 
       SUM(s.profit) AS total_profit
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l
     ON o.location_id = l.location_id
GROUP BY l.state
ORDER BY total_profit DESC
LIMIT 1;

--4.state have negative profit
SELECT l.state,
       SUM(s.profit) AS total_profit
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l
     ON o.location_id = l.location_id
GROUP BY l.state
HAVING SUM(s.profit) < 0
ORDER BY total_profit ASC;

--5.outlet type contributes most revenue
SELECT o.outlet_type,
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY o.outlet_type
ORDER BY total_revenue DESC
LIMIT 1;

--6.ship mode most frequently used
SELECT ship_mode, 
       COUNT(*) AS total_orders
FROM orders
GROUP BY ship_mode
ORDER BY total_orders DESC
LIMIT 1;

--Time Analysis
--1.monthly sales trends
SELECT 
       EXTRACT(YEAR FROM o.order_date) AS year,
       EXTRACT(MONTH FROM o.order_date) AS month,
       SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date),
         EXTRACT(MONTH FROM o.order_date) 
ORDER BY year, month ASC;

--2.month generated highest profit
SELECT 
       EXTRACT(YEAR FROM o.order_date) AS year,
       EXTRACT(MONTH FROM o.order_date) AS month,
	   SUM(s.profit) AS total_profit
FROM sales s 
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY  EXTRACT(YEAR FROM o.order_date),
          EXTRACT(MONTH FROM o.order_date)
ORDER BY total_profit DESC
LIMIT 1;

--3.compare yearly sales
SELECT 
      EXTRACT(YEAR FROM o.order_date) AS year,
	  SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date)
ORDER BY year;

--4.month with lowest revenue
SELECT 
       EXTRACT(YEAR FROM o.order_date) AS year,
	   EXTRACT(MONTH FROM o.order_date) AS month,
	   SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date),
         EXTRACT(MONTH FROM o.order_date)
ORDER BY total_sales ASC
LIMIT 1;

--5.calculate year-over-year(YoY) sales growth
WITH yearly_sales AS (
     SELECT  
	       EXTRACT(YEAR FROM o.order_date) AS year,
		   SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date)
)
SELECT 
      year, total_sales,
	  LAG(total_Sales) OVER(ORDER BY year) AS pervious_year_sales,
	  ROUND(
	      ((total_sales - 
	       LAG(total_Sales) OVER(ORDER BY year))  /
	       LAG(total_Sales) OVER(ORDER BY year)) * 100, 2) AS yoy_growth_precentage
FROM yearly_sales
ORDER BY year;

--Discount Analysis
--1.products receive highest avg discount
SELECT p.product_name, 
       ROUND(AVG(s.discount), 2) AS avg_discount
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY avg_discount DESC;

--2.does increasing the discount increase sale
 SELECT 
       CASE 
	       WHEN discount = 0 THEN 'No Discount'
		   WHEN discount > 0 AND discount <= 0.10 THEN '0% - 10%'
		   WHEN discount > 0.10 AND discount <= 0.20 THEN '11% - 20%'
		   WHEN discount > 0.20 AND discount <= 0.30 THEN '21% - 30%'
		   ELSE 'Above 30%'
		   END AS discount_range,
    COUNT(*) AS total_transcations,
	SUM(sales) AS total_sales,
	ROUND(AVG(sales), 2) AS avg_sales
FROM sales
GROUP BY discount_range
ORDER BY total_sales DESC;

--3.discount range produces the highest profit
SELECT 
      CASE 
	       WHEN discount = 0 THEN 'No Discount'
		   WHEN discount > 0 AND discount <= 0.10 THEN '0% - 10%'
		   WHEN discount > 0.10 AND discount <= 0.20 THEN '11% - 20%'
		   WHEN discount > 0.20 AND discount <= 0.30 THEN '21% - 30%'
		   ELSE 'Above 30%'
		   END AS discount_range,
	SUM(profit) AS total_profit
FROM sales
GROUP BY discount_range
ORDER BY total_profit DESC;

--Profitability
--1.products whose profit is below average profit
SELECT p.product_name, 
       SUM(s.profit) AS total_profit
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_name
HAVING SUM(s.profit) < (
                  SELECT AVG(product_profit) 
				  FROM (
                          SELECT SUM(profit) AS product_profit
						  FROM sales
						  GROUP BY product_id
				  ) AS average_profit
)
ORDER BY total_profit ASC;

--2.categories whose total profit above overall average category profit
SELECT p.category_of_goods, 
       SUM(s.profit) AS total_profit
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.category_of_goods
HAVING SUM(s.profit) > (
                    SELECT AVG(category_profit)
					FROM (
                            SELECT p.category_of_goods,
							       SUM(s.profit) AS category_profit
							FROM sales s
							JOIN products p
							ON s.product_id = p.product_id
							GROUP BY p.category_of_goods
					) AS average_category_profit
)
ORDER BY total_profit DESC;

--3.products having sales above average sales
SELECT p.product_name, 
       SUM(s.sales) AS total_sales
FROM sales s
JOIN products p
    ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name 
HAVING SUM(s.sales) > (
                  SELECT AVG(product_sales)
				  FROM(
                         SELECT SUM(sales) AS product_sales
						 FROM sales
						 GROUP BY product_id
				  ) AS average_product_sales
)
ORDER BY total_sales DESC;

--4.customers contributed more than 1% of total revenue
SELECT c.customer_name,
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN customers c
     ON s.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(s.sales) > (
                  SELECT SUM(sales) * 0.01
				  FROM sales
)
ORDER BY total_revenue DESC;

--5.regions contribute more than 20% of total company revenue
SELECT l.region, 
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l
     ON o.location_id = l.location_id
GROUP BY l.region
HAVING SUM(s.sales) > (
                SELECT SUM(sales) * 0.20
				FROM sales
)
ORDER BY total_revenue DESC;

--Advanced Analysis
--Ranking Function
--1.rank products by total sales
SELECT p.product_name, 
       SUM(s.sales) AS total_sales,
	   RANK() OVER(ORDER BY SUM(s.sales) DESC) AS sales_rank
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY sales_rank;

--2.rank customers by profit
SELECT c.customer_name,
       SUM(s.profit) AS total_profit,
	   DENSE_RANK() OVER(ORDER BY SUM(s.profit) DESC) AS profit_rank
FROM customers c
JOIN sales s
     ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY profit_rank;

--3.top 3 products in each category
WITH product_sales AS(
SELECT p.category_of_goods, p.product_name,
               SUM(s.sales) AS total_sales
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_name, p.product_id, p.category_oF_goods
),
ranked_products AS(
SELECT category_of_goods, product_name, total_sales,
        ROW_NUMBER() OVER(PARTITION BY category_of_goods ORDER BY total_sales DESC) AS product_rank
FROM product_sales
)
SELECT category_of_goods, product_name, total_sales, product_rank
FROM ranked_products
WHERE product_rank <=3
ORDER BY category_of_goods, product_rank;

--4.top 5 customers in each region
WITH customer_sales AS (
SELECT l.region, c.customer_name, 
       SUM(s.sales) AS total_sales
FROM sales s
JOIN customers c
     ON s.customer_id = c.customer_id
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l 
     ON o.location_id = l.location_id
GROUP BY l.region, c.customer_id, c.customer_name 
), 
ranked_customers AS (
SELECT region, customer_name, total_sales,
       ROW_NUMBER() OVER(PARTITION BY region ORDER BY total_sales DESC) AS customer_rank
FROM customer_sales
)
SELECT *
FROM ranked_customers
WHERE customer_rank <=5;

--5.rank states based on revenue
WITH state_revenue AS(
SELECT l.state,
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l
     ON o.location_id = l.location_id
GROUP BY l.state
),
ranked_state AS (
SELECT state, total_revenue,
       RANK() OVER(ORDER BY total_revenue DESC) AS state_rank
FROM state_revenue
)
SELECT *
FROM ranked_state;

--Navigation Function
--1.compare current month's sales with previous month
WITH monthly_sales AS (
SELECT 
       EXTRACT(YEAR FROM o.order_date) AS year,
       EXTRACT(MONTH FROM o.order_date) AS month,
	   SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date),
       EXTRACT(MONTH FROM o.order_date)
)
SELECT year, month, total_sales,
      LAG(total_sales) OVER(ORDER BY year, month) AS previous_month_sales
FROM monthly_sales
ORDER BY year, month;

--2.compare current month's profit with next month
WITH monthly_profit AS (
SELECT 
       EXTRACT(YEAR FROM o.order_date) AS year,
	   EXTRACT(MONTH FROM o.order_date) AS month,
	   SUM(s.profit) AS total_profit
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date),
	     EXTRACT(MONTH FROM o.order_date)
)
SELECT year, month, total_profit,
       LEAD(total_profit) OVER(ORDER BY year, month) AS next_month_profit
FROM monthly_profit 
ORDER BY year, month;

--3.calculate month-over-month sales growth
WITH monthly_sales AS (
     SELECT 
	       EXTRACT(YEAR FROM o.order_date) AS year,
	       EXTRACT(MONTH FROM o.order_date) AS month,
		   SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date), 
         EXTRACT(MONTH FROM o.order_date)
),
sales_growth AS(
SELECT 
      year, month, total_sales,
	  LAG(total_Sales) OVER(ORDER BY year, month) AS previous_month_sales
FROM monthly_sales
)
SELECT year, month, total_sales, previous_month_sales,
	  ROUND(
	      ((total_sales - 
	       previous_month_sales)  /
	       previous_month_sales) * 100, 2) AS mom_growth_percentage
FROM sales_growth
ORDER BY year, month;

--4.find products whose sales increased compared to the previous month
WITH monthly_product_sales AS (
SELECT p.product_name,
       EXTRACT(YEAR FROM o.order_date) AS year,
	   EXTRACT(MONTH FROM o.order_date) AS month,
	   SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_name, p.product_id,
       EXTRACT(YEAR FROM o.order_date),
	   EXTRACT(MONTH FROM o.order_date)
),
sales_comparison AS (
SELECT product_name, year, month, total_sales,
       LAG(total_sales) OVER(PARTITION BY product_name ORDER BY year, month) AS previous_month_sales
FROM monthly_product_sales
)
SELECT * 
FROM sales_comparison 
WHERE total_sales > previous_month_sales
ORDER BY product_name, year, month;

--Running Totals
--1.calculate cumulative sales by month
WITH monthly_sales AS (
SELECT 
      EXTRACT(YEAR FROM o.order_date) AS year,
	  EXTRACT(MONTH FROM o.order_date) AS month,
	  SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date),
	     EXTRACT(MONTH FROM o.order_date)
)
SELECT year, month, total_sales,
       SUM(total_sales) OVER(ORDER BY year, month) AS cumulative_sales
FROM monthly_sales
ORDER BY year, month;

--2.calculate cumulative profit by year
WITH yearly_profit AS (
SELECT 
      EXTRACT(YEAR FROM o.order_date) AS year,
	  SUM(s.profit) AS total_profit
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date)
)
SELECT year, total_profit,
       SUM(total_profit) OVER(ORDER BY year) AS cumulative_profit
FROM yearly_profit
ORDER BY year;

--3.running total of sales by category
WITH category_sales AS (
SELECT 
       EXTRACT(YEAR FROM o.order_date) AS year,
	   EXTRACT(MONTH FROM o.order_date) AS month,
       p.category_of_goods,
       SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id= o.order_id
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.category_of_goods,
         EXTRACT(YEAR FROM o.order_date),
	     EXTRACT(MONTH FROM o.order_date)
)
SELECT category_of_goods, year, month, total_sales,
       SUM(total_sales) OVER(PARTITION BY category_of_goods ORDER BY year, month) AS monthly_category_sales
FROM category_sales
ORDER BY category_of_goods, year, month;

--Moving Averages
--1.three-month moving average of sales
WITH monthly_sales AS (
SELECT 
      EXTRACT(YEAR FROM o.order_date) AS year,
	  EXTRACT(MONTH FROM o.order_date) AS month,
	  SUM(s.sales) AS total_sales
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date),
	     EXTRACT(MONTH FROM o.order_date)
)
SELECT year, month, total_sales,
       ROUND(AVG(total_sales) OVER(ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS three_month_moving_average
FROM monthly_sales
ORDER BY year, month;

--2.three-month moving average of profit
WITH monthly_profit AS (
SELECT 
      EXTRACT(YEAR FROM o.order_date) AS year,
	  EXTRACT(MONTH FROM o.order_date) AS month,
	  SUM(s.profit) AS total_profit
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date),
	     EXTRACT(MONTH FROM o.order_date)
)
SELECT year, month, total_profit,
       ROUND(AVG(total_profit) OVER(ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS three_month_moving_profit
FROM monthly_profit
ORDER BY year, month;

--Percentile Analysis
--1.divide customers into four spending groups 
WITH customer_sales AS (
SELECT c.customer_id, c.customer_name,
       SUM(s.sales) AS total_sales
FROM sales s
JOIN customers c
     ON s.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
)
SELECT customer_name, total_sales,
       NTILE(4) OVER(ORDER BY total_sales DESC) AS spending_quartiles
FROM customer_sales
ORDER BY total_sales DESC;

--2.divide products into five profit groups 
WITH product_groups AS (
SELECT p.product_id, p.product_name,
       SUM(s.profit) AS total_profit
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name
)
SELECT product_name, total_profit,
       NTILE(5) OVER(ORDER BY total_profit DESC) AS profit_quintiles
FROM product_groups
ORDER BY total_profit DESC;

--3.top 10% of customers by sales
WITH customer_sales AS (
SELECT c.customer_id, c.customer_name,
       SUM(s.sales) AS total_sales
FROM sales s
JOIN customers c
     ON s.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
),
customer_groups AS (
SELECT customer_name, total_sales, 
       NTILE(10) OVER(ORDER BY total_sales DESC) AS sales_deciles
FROM customer_sales
)
SELECT customer_name, total_sales, sales_deciles
FROM customer_groups
WHERE sales_deciles = 1
ORDER BY total_sales DESC;

--Window Aggregates
--1.each product's sales and the overall average sales
WITH product_sales AS (
SELECT p.product_name, 
       SUM(s.sales) AS total_sales
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name
)
SELECT product_name, total_sales,
       ROUND(AVG(total_sales) OVER(), 2) AS overall_average_sales
FROM product_sales
ORDER BY total_sales DESC;

--2.each customer's revenue and percentage contribution
WITH customer_revenue AS (
SELECT c.customer_id, c.customer_name, 
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN customers c
     ON s.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
)
SELECT customer_name, total_revenue,
       ROUND((total_revenue * 100.0) / 
	   SUM(total_revenue) OVER(), 2) AS revenue_percentage
FROM customer_revenue
ORDER BY total_revenue DESC;

--3.find products selling above the category average
WITH product_sales AS ( 
SELECT p.product_id, p.product_name, p.category_of_goods,
       SUM(s.sales) AS total_sales
FROM sales s
JOIN products p
     ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category_of_goods
),
category_average AS (
SELECT product_name, category_of_goods, total_sales,
       ROUND(AVG(total_sales) OVER(PARTITION BY category_of_goods), 2) AS category_average_sales
FROM product_sales
)
SELECT *
FROM category_average
WHERE total_sales > category_average_sales
ORDER BY category_of_goods, total_sales DESC;

--4.find regions where revenue exceeds the national average
WITH region_revenue AS (
SELECT l.region,
       SUM(s.sales) AS total_revenue
FROM sales s
JOIN orders o
     ON s.order_id = o.order_id
JOIN locations l
     ON o.location_id = l.location_id
GROUP BY l.region
),
national_average AS (
SELECT region, total_revenue,
       ROUND(AVG(total_revenue) OVER(), 2) AS national_average_revenue
FROM region_revenue
)
SELECT * 
FROM national_average
WHERE total_revenue > national_average_revenue
ORDER BY total_revenue DESC;

--exporting SQL query
SELECT
    o.order_id,
    o.order_date,
    o.sales_date,
    o.ship_date,
    o.ship_mode,
    o.outlet_type,
    o.year,
    c.customer_id,
    c.customer_name,
	c.date_of_birth,
    c.segment,
    p.product_id,
    p.product_name,
    p.category_of_goods,
    p.sub_category,
	l.location_id,
    l.country,
    l.region,
    l.state,
    l.city_type,
    l.postal_code,
	s.sale_id,
    s.sales,
    s.quantity,
    s.discount,
    s.profit
FROM orders o
JOIN customers c
     ON o.customer_id = c.customer_id
JOIN sales s
     ON o.order_id = s.order_id
JOIN products p
     ON s.product_id = p.product_id
JOIN locations l
     ON o.location_id = l.location_id;
