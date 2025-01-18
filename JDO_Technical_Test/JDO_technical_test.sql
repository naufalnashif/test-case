---------------------------------------------------------------------------
/* TASK 1 : Predictive Feature Analysis for Missing Data */
---------------------------------------------------------------------------

-- Membuat tabel customer
CREATE TABLE public.customer (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(255),
    address VARCHAR(255)
);
INSERT INTO public.customer (id, name, email, phone, address) VALUES
(1, 'Rizaldy Uto', 'uto@example.com', '1234567890', NULL),
(2, 'Caemila', NULL, NULL, NULL),
(3, NULL, 'caem@example.com', '9876543210', 'Elm Street'),
(4, NULL, NULL, NULL, NULL),
(5, 'Johan Chris', 'jo@example.com', '5555555555', 'Pine Street');

--------------------------------------------------------------------
-- Membuat tabel orders
CREATE TABLE public.orders (
    id INT PRIMARY KEY, 
    customer_id INT, 
    order_date DATE, 
    delivery_date DATE, 
    tracking_number VARCHAR(128), 
    FOREIGN KEY (customer_id) REFERENCES customer(id)
);
INSERT INTO public.orders (id, customer_id, order_date, delivery_date, tracking_number) VALUES
(1, 1, '2025-01-01', '2025-01-03', '123-ABC'),
(2, 1, '2025-01-02', NULL, '456-DEF'),
(3, 2, NULL, NULL, NULL),
(4, 3, '2025-01-03', '2025-01-04', NULL),
(5, 4, NULL, NULL, NULL);


---------------------------------------------------------------------
select *
from public.customer

select * 
from public.orders

---------------------------------------------------------------------

WITH cte_main AS (
    SELECT 
        'customer' AS table_name,
        'name' AS column_name,
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE name IS NULL) AS missing_value
    FROM public.customer
    UNION ALL
    SELECT 
        'customer',
        'address',
        COUNT(*),
        COUNT(*) FILTER (WHERE address IS NULL)
    FROM public.customer
    UNION ALL
    SELECT 
        'customer',
        'phone',
        COUNT(*),
        COUNT(*) FILTER (WHERE phone IS NULL)
    FROM public.customer
    UNION ALL
    SELECT 
        'orders',
        'order_date',
        COUNT(*),
        COUNT(*) FILTER (WHERE order_date IS NULL)
    FROM public.orders
    UNION ALL
    SELECT 
        'orders',
        'delivery_date',
        COUNT(*),
        COUNT(*) FILTER (WHERE delivery_date IS NULL)
    FROM public.orders
    UNION ALL
    SELECT 
        'orders',
        'tracking_number',
        COUNT(*),
        COUNT(*) FILTER (WHERE tracking_number IS NULL)
    FROM public.orders
)
SELECT 
    table_name,
    column_name,
    total_rows,
    missing_value,
    ROUND((missing_value::DECIMAL / total_rows) * 100, 2) || '%' AS missing_percentage
FROM cte_main
ORDER BY missing_percentage DESC;



---------------------------------------------------------------------------
/* TASK 2 : Dealer Performance and Product Analysis */
---------------------------------------------------------------------------
SELECT *
FROM public.dealers d 

SELECT *
FROM public.products p

SELECT *
FROM public.sales s 
order by dealer_id 


"
Scenario :
You are working as a data analyst for a company that tracks dealer performance and product sales. The management has requested a comprehensive report to gain insights into
dealer performance, product profitability, and forecast accuracy. This report must include detailed segmentation and ranking based on various metrics.
Task :
Create a detailed SQL-based report that answers the following questions about dealer and product performance :
1. Identify the top-performing and least-performing dealers in terms of total sales. Include dealer ID, dealer name, total sales, and their rank.
2. Group dealers into sales deciles based on their total sales and identify the decile for each dealer.
3. Segment products into quartiles based on total sales and list each product's quartile.
4. Rank dealers based on their income percentile and list the percentile rank for each dealer.
5. Categorize dealers into 5 age groups based on their age and display the group for each dealer.
6. Rank products by sales performance within each dealer and identify the top-performing product for each dealer.
7. Segment monthly sales into deciles and identify the decile for each month.
8. Analyze subscription types and sales performance to categorize dealers into 5 groups.
9. Evaluate forecast accuracy for each dealer by calculating the percentage difference between forecasted and actual sales. Group dealers into 5 categories based on their
forecast accuracy.
10. Rank products into deciles based on their profit margin.
"

-- 1. Identify the top-performing and least-performing dealers in terms of total sales. Include dealer ID, dealer name, total sales, and their rank.
with cte as (
	select
		dealer_id ,
		dealer_name ,
		SUM(sale_amount) as total_sales
	from public.dealers d 
	left join public.sales s using (dealer_id)
	left join public.products p using (product_id)
	group by dealer_id , dealer_name 
),
cte_rank as (
	select 
		*, 
		rank() over (order by total_sales DESC) as dealer_rank
	from cte
)
select 
	dealer_id,
	dealer_name,
	total_sales,
	dealer_rank
from cte_rank
where dealer_rank = 1 or dealer_rank = (
	select
		MAX(dealer_rank)
	from cte_rank
);


-- 2. Group dealers into sales deciles based on their total sales and identify the decile for each dealer.
with cte as (
	select
		dealer_id ,
		dealer_name ,
		SUM(sale_amount) as total_sales
	from public.dealers d 
	left join public.sales s using (dealer_id)
	left join public.products p using (product_id)
	group by dealer_id , dealer_name 
)
select 
	*,
	ntile (10) over (order by total_sales desc) as decile
from cte;


-- 3. Segment products into quartiles based on total sales and list each product's quartile.

with cte as (
	select
		product_id,
		product_name,
		SUM(sale_amount) as total_sales
	from public.dealers d 
	left join public.sales s using (dealer_id)
	left join public.products p using (product_id)
	group by product_id , product_name 
)
select 
	product_id,
	product_name,
	total_sales,
	ntile (4) over (order by total_sales desc) as quartiles
from cte ;

-- 4. Rank dealers based on their income percentile and list the percentile rank for each dealer.
SELECT 
	dealer_id,
	dealer_name,
	dealer_income ,
	percent_rank() OVER (ORDER BY dealer_income DESC) AS percentile
FROM public.dealers


-- 5. Categorize dealers into 5 age groups based on their age and display the group for each dealer.
select
	dealer_id,
	dealer_name,
	dealer_age ,
	ntile(5) over (order by dealer_age DESC) as age_group
from public.dealers d 


-- 6. Rank products by sales performance within each dealer and identify the top-performing product for each dealer.
with cte as (
	select
		dealer_id,
		dealer_name,
		product_id,
		product_name,
		SUM(sale_amount) as total_sales
	from public.dealers d 
	left join public.sales s using (dealer_id)
	left join public.products p using (product_id)
	group by dealer_id, dealer_name, product_id , product_name 
),
cte_2 as (
	select 
		*,
		rank() over (partition by dealer_name order by total_sales DESC) as rank_dealer_product
	from cte
)
select *
from cte_2
where rank_dealer_product = 1

-- 7. Segment monthly sales into deciles and identify the decile for each month.
WITH cte AS (
    SELECT 
        EXTRACT(MONTH FROM TO_DATE(sale_date, 'YYYY-MM-DD')) AS month_date,
        SUM(sale_amount) AS total_sales
    FROM public.sales s
    GROUP BY EXTRACT(MONTH FROM TO_DATE(sale_date, 'YYYY-MM-DD'))
)
SELECT 
    month_date,
    total_sales,
    NTILE(10) OVER (ORDER BY total_sales DESC) AS decile
FROM cte
ORDER BY month_date;


-- 8. Analyze subscription types and sales performance to categorize dealers into 5 groups.
with cte as (
	select
		dealer_id,
		dealer_name,
		subscription_service,
		SUM(sale_amount) as total_sales
	from public.dealers d 
	left join public.sales s using (dealer_id)
	left join public.products p using (product_id)
	group by dealer_id, dealer_name, subscription_service
)
select 
	*,
	ntile(5) over (order by total_sales DESC) as five_group
from cte
order by five_group;

-- 9. Evaluate forecast accuracy for each dealer by calculating the percentage difference between forecasted and actual sales. Group dealers into 5 categories based on their
-- forecast accuracy.

WITH cte AS (
    SELECT
        dealer_id,
        dealer_name,
        SUM(sale_amount) AS actual_sales,
        SUM(forecast_amount) AS forecasted_sales
    FROM public.dealers d 
    LEFT JOIN public.sales s USING (dealer_id)
    GROUP BY dealer_id, dealer_name
),
cte_2 as (
	SELECT 
	    dealer_id,
	    dealer_name,
	    actual_sales,
	    forecasted_sales,
	    ROUND(AVG(ABS(forecasted_sales - actual_sales)::decimal / NULLIF(actual_sales, 0) * 100), 2) AS forecast_error
	FROM cte
	GROUP BY dealer_id, dealer_name, actual_sales, forecasted_sales
)
select 
	*,
	(100 - forecast_error) as forecast_accuracy,
	ntile(5) over (order by (100 - forecast_error) DESC) as accuracy_group
from cte_2;


-- 10. Rank products into deciles based on their profit margin.
select
	*,
	rank() over (order by product_margin DESC) as rank_product
from public.products p 









