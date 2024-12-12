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
	p."Margin",
	AVG(s."Sales" * p."Margin") as avg_margin
from public.salesdata s 
left join public.productdata p using("Product")
group by s."Product" , p."Margin"
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
        COALESCE(LAG(total_sales, 1) OVER (PARTITION BY "DealerName" ORDER BY month_payment), 0) AS prev_month_sales,
        CASE 
            WHEN COALESCE(LAG(total_sales, 1) OVER (PARTITION BY "DealerName" ORDER BY month_payment), 0) = 0 THEN 0
            ELSE ROUND(((total_sales - COALESCE(LAG(total_sales, 1) OVER (PARTITION BY "DealerName" ORDER BY month_payment), 0)) 
                / COALESCE(LAG(total_sales, 1) OVER (PARTITION BY "DealerName" ORDER BY month_payment), 1)::DECIMAL), 2)
        END AS mom
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

-----------------------------------------

"
Creating tasks that specifically focus on using window functions for segmentation, such as
decile segmentation, is an excellent way to assess a candidate's advanced SQL skills. Below
are 10 tasks designed to test proficiency in these areas,
Task 1: Dealer Sales Decile Segmentation
Objective: Segment dealers into deciles based on total sales.
Task 2: Product Sales Quartile Segmentation
Objective: Segment products into quartiles based on total sales.
Task 3: Dealer Income Percentile Ranking
Objective: Rank dealers based on their income in percentiles.
Task 4: Dealer Age Segmentation
Objective: Segment dealers into 5 groups based on dealer age.
Task 5: Storage Capacity Segmentation
Objective: Segment dealers based on their storage capacity.
Task 6: Sales Performance Ranking by Product
Objective: Rank products by sales performance within each dealer.
Task 7: Monthly Sales Segmentation
Objective: Segment monthly sales into deciles.
Task 8: Subscription Service Segmentation
Objective: Segment dealers based on their subscription to credit services and sales performance.
Task 9: Forecast Accuracy Segmentation
Objective: Segment dealers based on the accuracy of their sales forecasts.
Task 10: Product Margin Decile Ranking
Objective: Rank products into deciles based on their margin.
"

----------------------------------------
-- Task 1: Dealer Sales Decile Segmentation
-- Objective: Segment dealers into deciles based on total sales.
----------------------------------------
WITH cte_total_sales AS (
    SELECT 
        "Dealer",
        SUM("Sales") AS total_sales
    FROM public.salesdata
    GROUP BY "Dealer"
),
cte_decile_segment AS (
    SELECT 
        "Dealer",
        total_sales,
        NTILE(10) OVER (ORDER BY total_sales DESC) AS decile
    FROM cte_total_sales
)
SELECT 
    "Dealer",
    total_sales,
    decile
FROM cte_decile_segment
ORDER BY decile, total_sales DESC;



----------------------------------------
-- Task 2: Product Sales Quartile Segmentation
-- Objective: Segment products into quartiles based on total sales.
----------------------------------------
WITH cte_total_sales AS (
    SELECT 
        "Dealer",
        SUM("Sales") AS total_sales
    FROM public.salesdata
    GROUP BY "Dealer"
),
cte_decile_segment AS (
    SELECT 
        "Dealer",
        total_sales,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS decile
    FROM cte_total_sales
)
SELECT 
    "Dealer",
    total_sales,
    decile
FROM cte_decile_segment
ORDER BY decile, total_sales DESC;


----------------------------------------
-- Task 3: Dealer Income Percentile Ranking
-- Objective: Rank dealers based on their income in percentiles.
----------------------------------------
SELECT
    "Dealer",
    "Dealer Income",
    ROUND(CAST(PERCENT_RANK() OVER (ORDER BY "Dealer Income") * 100 AS NUMERIC), 0) AS income_percentile_rank
FROM public.dealerdata
ORDER BY income_percentile_rank;


----------------------------------------
-- Task 4: Dealer Age Segmentation
-- Objective: Segment dealers into 5 groups based on dealer age.
----------------------------------------
select 
	"Dealer",
	"Dealer Age",
	ntile (5) over (order by "Dealer Age" ASC) as five_group
from public.dealerdata


----------------------------------------
-- Task 5: Storage Capacity Segmentation
-- Objective: Segment dealers based on their storage capacity.
----------------------------------------
WITH cte AS (
	select 
		"Dealer",
		"Storage Capacity",
		ntile (3) over (order by "Storage Capacity" ASC) as three_group
	from public.dealerdata
)
SELECT 
	*,
	CASE
		WHEN three_group = 1 then 'Low Capacity'
		WHEN three_group = 2 then 'Medium Capacity'
		WHEN three_group = 3 then 'High Capacity'
	end as storage_segment
from cte
	

----------------------------------------
-- Task 6: Sales Performance Ranking by Product
-- Objective: Rank products by sales performance within each dealer.
----------------------------------------
select
	"Dealer",
	"Product",
	"total_sales",
	dense_rank () over (partition by "Dealer" order by total_sales DESC) as rank_product
from (
	SELECT 
		"Dealer",
		"Product",
		SUM("Sales") AS total_sales
	FROM salesdata
	GROUP BY "Dealer", "Product"
)
order by "Dealer"


----------------------------------------
-- Task 7: Monthly Sales Segmentation
-- Objective: Segment monthly sales into deciles.
----------------------------------------
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
),
cte_main as (
	SELECT 
	    d."DealerName",
	    m.month_payment,
	    COALESCE(COUNT(a."DealerName"), 0) AS total_sales
	FROM 
		(SELECT DISTINCT "DealerName" FROM public.paymentdata) d
	CROSS JOIN cte_month_payment m(month_payment)
	LEFT JOIN cte_agg2 a ON a."DealerName" = d."DealerName" AND a.month_payment = m.month_payment
	GROUP BY d."DealerName", m.month_payment
	ORDER BY d."DealerName", m.month_payment
)
select 
	month_payment,
	"DealerName",
	total_sales,
	ntile (10) over(partition by month_payment order by total_sales) as decile
from cte_main;



----------------------------------------
-- Task 8: Subscription Service Segmentation
-- Objective: Segment dealers based on their subscription to credit services and sales performance.
----------------------------------------
with cte_join as (
	select 
		d."Dealer",
		d."Subscription to Credit services",
		sum(s."Sales") as total_sales
	from dealerdata d
	left join salesdata s using ("Dealer")
	group by 
		d."Dealer", 
		d."Subscription to Credit services" 
	order by "Dealer"
),
cte_main as (
	select 
		*,
		PERCENT_RANK() OVER (partition by "Subscription to Credit services" ORDER BY total_sales) AS percentile_rank
	from cte_join
)
select 
	*,
	case 
		when "Subscription to Credit services" = 0 and percentile_rank > 0.75 then 'Non Subscribe - High Performer'
		when "Subscription to Credit services" = 0 and percentile_rank > 0.5 then 'Non Subscribe - Mid Performer'
		when "Subscription to Credit services" = 0 and percentile_rank < 0.5 then 'Non Subscribe - Low Performer'
		when "Subscription to Credit services" = 1 and percentile_rank > 0.75 then 'Subscribe - High Performer'
		when "Subscription to Credit services" = 1 and percentile_rank > 0.5 then 'Subscribe - Mid Performer'
		when "Subscription to Credit services" = 1 and percentile_rank < 0.5 then 'Subscribe - Low Performer'
	end as segment
from cte_main;



----------------------------------------
-- Task 9: Forecast Accuracy Segmentation
-- Objective: Segment dealers based on the accuracy of their sales forecasts.
----------------------------------------
with cte_accuracy as (
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
	order by s."Dealer", s."Product"
),
cte_mean_accuracy as (
	select
		"Dealer",
		AVG(accuracy) as avg_accuracy
	from cte_accuracy
	group by "Dealer"
)
select 
	"Dealer",
	avg_accuracy,
	case
		when ntile(3) over (order by avg_accuracy) = 1 then 'Low Accuracy'
		when ntile(3) over (order by avg_accuracy) = 2 then 'Mid Accuracy'
		when ntile(3) over (order by avg_accuracy) = 3 then 'High Accuracy'
	end segment_accuarcy
from cte_mean_accuracy;



----------------------------------------
-- Task 10: Product Margin Decile Ranking
-- Objective: Rank products into deciles based on their margin.
----------------------------------------
-- By margin per product
select 
	"Product",
	"Margin",
	ntile(10) over (order by "Margin" DESC) as rank_margin
from productdata;

-- By total margin
with cte_join as (
	select
		s."Product",
		SUM(s."Sales") as total_sales,
		p."Margin",
		SUM(s."Sales" * p."Margin") as total_margin
	from public.salesdata s 
	left join public.productdata p using("Product")
	group by s."Product" , p."Margin"
	order by s."Product"
)
select 
	*, 
	ntile(10) over (order by total_margin DESC) as rank_margin
from cte_join;