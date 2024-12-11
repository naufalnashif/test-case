/* SQL Test CASE */

---------------------------------------
SELECT *
FROM public.salesdata s ;

SELECT *
FROM public.dealerdata d ;

SELECT *
FROM public.productdata p ;

SELECT *
FROM public.paymentdata p ;

SELECT *
FROM public.forecast f;

---------------------------------------
"
Creating 10 tasks that encompass various aspects of SQL, such as joins, aggregations,
subqueries, and data analysis.


Task 1: Join Sales and Dealer Data
Objective: Combine sales data with dealer information and calculate total sales for each dealer.
Task 2: Dealer Sales by Product
Objective: Find the total sales for each product by each dealer.
Task 3: Sales Forecast Accuracy
Objective: Compare actual sales with forecasted sales for each dealer and product.
Task 4: Product Margin Analysis
Objective: Calculate the total sales and average margin for each product.
Task 5: Dealer Performance Analysis
Objective: Analyze the performance of dealers based on their age and total sales.
Task 6: Dealer Subscription Effect on Sales
Objective: Determine the effect of subscription to credit services on dealer sales.
Task 7: Monthly Sales Trend Analysis
Objective: Analyze the monthly sales trend for each dealer.
Task 8: Storage Capacity and Sales Correlation
Objective: Analyze if there's a correlation between storage capacity and total sales.
Task 9: Sales Aggregation with Conditional Logic
Objective: Calculate total sales, categorizing dealers based on whether they are road facing.
Task 10: Advanced Dealer Performance Analysis
Objective: Perform a complex analysis involving multiple tables to find dealers with above-average
income and their total sales.
"

----------------------------------------
-- Task 1 : Join Sales and Dealer data
-- Objective: Combine sales data with dealer information and calculate total sales for each dealer.
----------------------------------------

select 
	d."Dealer",
	d."Storage Capacity",
	d."Road Facing" ,
	d."Store Count" ,
	d."Dealer Age" ,
	d."Dealer Income" ,
	d."Subscription to Credit services",
	SUM(s."Sales") as total_sales
from public.salesdata s
right join public.dealerdata d using ("Dealer")
group by 
	d."Dealer",
	d."Storage Capacity",
	d."Road Facing" ,
	d."Store Count" ,
	d."Dealer Age" ,
	d."Dealer Income" ,
	d."Subscription to Credit services"
order by d."Dealer";

-- OR


select
	sq1."Dealer" ,
	d."Storage Capacity",
	d."Road Facing" ,
	d."Store Count" ,
	d."Dealer Age" ,
	d."Dealer Income" ,
	d."Subscription to Credit services" ,
	sq1.total_sales
from (
	select
		s."Dealer",
		sum("Sales") as total_sales
	from public.salesdata s
	group by s."Dealer"
	order by s."Dealer"
) sq1
left join public.dealerdata d on sq1."Dealer" = d."Dealer";




----------------------------------------
-- Task 2: Dealer Sales by Product
-- Objective: Find the total sales for each product by each dealer.
----------------------------------------
select
	s."Dealer",
	s."Product",
	sum("Sales") as total_sales
from public.salesdata s
group by s."Product", s."Dealer"
order by s."Dealer", s."Product" ;



----------------------------------------
-- Task 3: Sales Forecast Accuracy
-- Objective: Compare actual sales with forecasted sales for each dealer and product.
----------------------------------------

select 
	s."Dealer" ,
	s."Product",
	SUM(s."Sales") as total_sales,
	SUM(f."FC") as total_forecast,
	AVG(ABS(s."Sales" - f."FC")) as mae,
	ROUND(AVG((ABS(s."Sales" - f."FC")::decimal / NULLIF(s."Sales", 0)) * 100), 2) AS mape,
	ROUND(100 - LEAST(AVG((ABS(s."Sales" - f."FC")::decimal / NULLIF(s."Sales", 0)) * 100), 100), 2) AS accuracy
from public.salesdata s 
left join public.forecast f on s."Dealer" = f."Dealer" and s."Product" = f."Product"
group by s."Dealer", s."Product"
order by s."Dealer", s."Product";


----------------------------------------
-- Task 4: Product Margin Analysis
-- Objective: Calculate the total sales and average margin for each product.
----------------------------------------
select
	s."Product",
	SUM(s."Sales") as total_sales,
	AVG(p."Margin") as avg_margin
from public.salesdata s 
left join public.productdata p using("Product")
group by s."Product" 
order by s."Product" ;


----------------------------------------
-- Task 5: Dealer Performance Analysis
-- Objective: Analyze the performance of dealers based on their age and total sales.
----------------------------------------
select 
	d."Dealer Age" ,
	count(d."Dealer") as total_dealer,
	SUM(s."Sales") as total_sales,
	AVG(s."Sales") as avg_sales
from public.salesdata s
right join public.dealerdata d using ("Dealer")
group by 
	d."Dealer Age"
order by total_sales DESC;

-- OR

select 
	d."Dealer Age" ,
	count(d."Dealer") as total_dealer,
	SUM(s."Sales") as total_sales,
	AVG(s."Sales") as avg_sales
from public.salesdata s
right join public.dealerdata d using ("Dealer")
group by 
	d."Dealer Age"
order by d."Dealer Age";



----------------------------------------
-- Task 6: Dealer Subscription Effect on Sales
-- Objective: Determine the effect of subscription to credit services on dealer sales.
----------------------------------------
select 
	d."Subscription to Credit services",
	SUM(s."Sales") as total_sales,
	COUNT(s."Dealer") as total_dealer,
	AVG(s."Sales") as avg_sales
from public.salesdata s
right join public.dealerdata d using ("Dealer")
group by 
	d."Subscription to Credit services"
order by SUM(s."Sales") desc, AVG(s."Sales") DESC;



----------------------------------------
-- Task 7: Monthly Trend Analysis
-- Objective: Analyze the monthly sales trend for each dealer.
----------------------------------------
-- Include 0 for months with no sales, rather than excluding dealers.
-- Assume that each Payment Date corresponds to 1 sale, as there is no column for total_sales by month.
WITH cte_agg2 AS (
    SELECT
        p."DealerName", 
        EXTRACT(MONTH FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS month_payment,
        EXTRACT(YEAR FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS year_payment
    FROM public.paymentdata p
),
cte_month_payment as (
    select distinct
        EXTRACT(MONTH FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS month_payment
    FROM public.paymentdata p
    order by month_payment
)
SELECT 
    d."DealerName",
    m.month_payment,
    COALESCE(COUNT(a."DealerName"), 0) AS total_sales
FROM 
	(SELECT DISTINCT "DealerName" FROM public.paymentdata) d
CROSS JOIN cte_month_payment m(month_payment)
LEFT JOIN cte_agg2 a ON a."DealerName" = d."DealerName" AND a.month_payment = m.month_payment
GROUP BY d."DealerName", m.month_payment
ORDER BY d."DealerName", m.month_payment;


----------------------------------------
-- Task 8: Storage Capacity and Sales Correlation
-- Objective: Analyze if there's a correlation between storage capacity and total sales.
----------------------------------------
select 
	d."Dealer",
	d."Storage Capacity",
	SUM(s."Sales") as total_sales
from public.salesdata s
right join public.dealerdata d using ("Dealer")
group by 
	d."Dealer",
	d."Storage Capacity"
order by SUM(s."Sales") DESC;


----------------------------------------
-- Task 9: Sales Aggregation with Conditional Logic
-- Objective: Calculate total sales, categorizing dealers based on whether they are road facing.
----------------------------------------
select 
	d."Road Facing",
	SUM(s."Sales") as total_sales,
	COUNT(s."Dealer") as total_dealer,
	AVG(s."Sales") as avg_sales
from public.salesdata s
right join public.dealerdata d using ("Dealer")
group by 
	d."Road Facing"
order by SUM(s."Sales") desc, AVG(s."Sales") DESC;

----------------------------------------
-- Task 10: Advanced Dealer Performance Analysis
-- Objective: Perform a complex analysis involving multiple tables to find dealers with above-average
----------------------------------------
WITH cte_join1 AS (
    SELECT 
        d."Dealer",
        d."Storage Capacity",
        d."Road Facing",
        d."Store Count",
        d."Dealer Age",
        d."Dealer Income",
        d."Subscription to Credit services",
        SUM(s."Sales") AS total_sales
    FROM public.salesdata s
    RIGHT JOIN public.dealerdata d USING ("Dealer")
    GROUP BY 
        d."Dealer",
        d."Storage Capacity",
        d."Road Facing",
        d."Store Count",
        d."Dealer Age",
        d."Dealer Income",
        d."Subscription to Credit services"
)
SELECT 
    *
FROM cte_join1
WHERE 
    "Dealer Income" > (SELECT AVG("Dealer Income") FROM cte_join1) 
    AND total_sales > (SELECT AVG(total_sales) FROM cte_join1);

----------------------------------------
"
Creating 10 tasks focused on using window functions to analyze dealer, storage, product,
and sales performance will provide a thorough assessment of a senior data analyst's skills in
SQL.

Task 1: Dealer Sales Ranking
Objective: Rank each dealer by their total sales.
Task 2: Cumulative Sales by Dealer
Objective: Calculate the cumulative sales for each dealer over time.
Task 3: Moving Average of Sales
Objective: Compute a 3-month moving average of sales for each dealer.
Task 4: Dealer Sales Growth Percentage
Objective: Calculate month-over-month sales growth percentage for each dealer.
Task 5: Dealer Income Percentile Rank
Objective: Determine the percentile rank of each dealer based on income.
Task 6: Top Performing Products by Sales
Objective: Identify the top 3 performing products by sales for each dealer.
Task 7: Dealer Sales Comparison to Average
Objective: Compare each dealer's sales to the average sales of all dealers.
Task 8: Dealer Age and Sales Correlation
Objective: Analyze correlation between dealer age and sales performance.
Task 9: Product Sales and Margin Analysis
Objective: Analyze sales and margin for each product.
Task 10: Sequential Invoice Analysis
Objective: Analyze the sequential order of invoices for each dealer.
"

----------------------------------------
-- Task 1: Dealer Sales Ranking
-- Objective: Rank each dealer by their total sales.
----------------------------------------
select 
	d."Dealer",
	SUM(s."Sales") as total_sales,
	dense_rank () over (order by SUM(s."Sales") DESC) as dense_rank
from public.dealerdata d 
left join public.salesdata s using ("Dealer")
group by d."Dealer"


----------------------------------------
-- Task 2: Cumulative Sales by Dealer
-- Objective: Calculate the cumulative sales for each dealer over time.
----------------------------------------
SELECT
	"DealerName",
	TO_DATE("PaymentDate", 'DD-MM-YYYY') AS payment_date,
	SUM(COUNT("DealerName")) OVER(PARTITION BY "DealerName" ORDER BY TO_DATE("PaymentDate", 'DD-MM-YYYY')) AS cumulative_sales
from public.paymentdata
group by "DealerName", "PaymentDate" 


----------------------------------------
-- Task 3: Moving Average of Sales
-- Objective: Compute a 3-month moving average of sales for each dealer.
----------------------------------------
-- Assume that each Payment Date corresponds to 1 sale, as there is no column for total_sales by month.
with cte_agg_sales as (
	SELECT 
	    d."DealerName",
	    m.month_payment,
	    COALESCE(COUNT(a."DealerName"), 0) AS total_sales
	FROM 
		(SELECT DISTINCT "DealerName" FROM public.paymentdata) d
	CROSS JOIN (
	    select distinct
	        EXTRACT(MONTH FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS month_payment
	    FROM public.paymentdata p
	) m(month_payment)
	LEFT JOIN (
	    SELECT
	        p."DealerName", 
	        EXTRACT(MONTH FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS month_payment,
	        EXTRACT(YEAR FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS year_payment
	    FROM public.paymentdata p
	) a ON a."DealerName" = d."DealerName" AND a.month_payment = m.month_payment
	GROUP BY d."DealerName", m.month_payment
	ORDER BY d."DealerName", m.month_payment
),
cte_moving_avg_sales AS (
    SELECT
        "DealerName",
        month_payment,
        total_sales,
        AVG(total_sales) OVER (
            PARTITION BY "DealerName"
            ORDER BY month_payment
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3_months
    FROM cte_agg_sales
)
SELECT *
FROM cte_moving_avg_sales
ORDER BY "DealerName", month_payment;


----------------------------------------
-- Task 4: Dealer Sales Growth Percentage
-- Objective: Calculate month-over-month sales growth percentage for each dealer.
----------------------------------------
-- Assume that each Payment Date corresponds to 1 sale, as there is no column for total_sales by month.
with cte_agg_sales as (
	SELECT 
	    d."DealerName",
	    m.month_payment,
	    COALESCE(COUNT(a."DealerName"), 0) AS total_sales
	FROM 
		(SELECT DISTINCT "DealerName" FROM public.paymentdata) d
	CROSS JOIN (
	    select distinct
	        EXTRACT(MONTH FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS month_payment
	    FROM public.paymentdata p
	) m(month_payment)
	LEFT JOIN (
	    SELECT
	        p."DealerName", 
	        EXTRACT(MONTH FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS month_payment,
	        EXTRACT(YEAR FROM TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS year_payment
	    FROM public.paymentdata p
	) a ON a."DealerName" = d."DealerName" AND a.month_payment = m.month_payment
	GROUP BY d."DealerName", m.month_payment
	ORDER BY d."DealerName", m.month_payment
),
cte_mom_sales AS (
    SELECT
        "DealerName",
        month_payment,
        total_sales,
        coalesce(LAG(total_sales, 1) OVER (PARTITION BY "DealerName" ORDER BY month_payment),0) AS prev_month_sales
    FROM cte_agg_sales
)
SELECT *
FROM cte_mom_sales
ORDER BY "DealerName", month_payment;


----------------------------------------
-- Task 5: Dealer Income Percentile Rank
-- Objective: Determine the percentile rank of each dealer based on income.
----------------------------------------
SELECT
    "Dealer",
    "Dealer Income",
    ROUND(CAST(PERCENT_RANK() OVER (ORDER BY "Dealer Income") * 100 AS NUMERIC), 0) AS income_percentile_rank
FROM public.dealerdata
ORDER BY income_percentile_rank;


----------------------------------------
-- Task 6: Top Performing Products by Sales
-- Objective: Identify the top 3 performing products by sales for each dealer.
----------------------------------------
WITH cte_ranked_sales AS (
    SELECT
        s."Dealer",
        s."Product",
        SUM(s."Sales") AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s."Dealer" ORDER BY SUM(s."Sales") DESC) AS product_rank
    FROM public.salesdata s
    GROUP BY s."Dealer", s."Product"
)
SELECT 
    "Dealer",
    "Product",
    product_rank,
    total_sales
FROM cte_ranked_sales
WHERE product_rank <= 3
ORDER BY "Dealer", product_rank;


----------------------------------------
-- Task 7: Dealer Sales Comparison to Average
-- Objective: Compare each dealer's sales to the average sales of all dealers.
----------------------------------------
WITH cte_join1 AS (
    SELECT 
        d."Dealer",
        SUM(s."Sales") AS total_sales
    FROM public.salesdata s
    RIGHT JOIN public.dealerdata d USING ("Dealer")
    GROUP BY 
        d."Dealer"
)
SELECT 
    *,
    (SELECT AVG(total_sales) FROM cte_join1) as avg_all,
    ROUND((total_sales/ (SELECT AVG(total_sales) FROM cte_join1)), 2) as comp
FROM cte_join1
order by comp desc


----------------------------------------
-- Task 8: Dealer Age and Sales Correlation
-- Objective: Analyze correlation between dealer age and sales performance.
----------------------------------------
select 
	d."Dealer",
	d."Dealer Age",
	SUM(s."Sales") as total_sales
from public.salesdata s
right join public.dealerdata d using ("Dealer")
group by 
	d."Dealer",
	d."Dealer Age"
order by SUM(s."Sales") DESC;


----------------------------------------
-- Task 9: Product Sales and Margin Analysis
-- Objective: Analyze sales and margin for each product.
----------------------------------------

SELECT 
    s."Product",
    SUM(s."Sales") AS total_sales,
    p."Margin",
    SUM(s."Sales" * p."Margin") AS total_margin
FROM public.salesdata s
LEFT JOIN productdata p USING ("Product")
GROUP BY s."Product", p."Margin"
ORDER BY s."Product";


----------------------------------------
-- Task 10: Sequential Invoice Analysis
-- Objective: Analyze the sequential order of invoices for each dealer.
----------------------------------------
SELECT
    p."DealerName",
    p."InvoiceNo",
    TO_DATE(p."PaymentDate", 'DD-MM-YYYY') as PaymentDate,
    ROW_NUMBER() OVER (PARTITION BY p."DealerName" ORDER BY TO_DATE(p."PaymentDate", 'DD-MM-YYYY')) AS invoice_sequence
FROM public.paymentdata p
JOIN public.dealerdata d ON p."DealerName" = d."Dealer"
ORDER BY p."DealerName", TO_DATE(p."PaymentDate", 'DD-MM-YYYY');
