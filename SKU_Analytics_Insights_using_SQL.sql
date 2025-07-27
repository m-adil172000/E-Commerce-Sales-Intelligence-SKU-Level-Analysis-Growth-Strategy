
-- OVERVIEW OF THE DATA --
select * from sales_data;
select * from glance_views;




-- Problem-1: Identify the most expensive SKU, on average, over the entire time period.

SELECT
	SKU_NAME, 
    ROUND(SUM(ORDERED_REVENUE) / NULLIF(SUM(ORDERED_UNITS), 0), 2) AS avg_selling_price
FROM sales_data
GROUP BY SKU_NAME
ORDER BY avg_selling_price DESC
LIMIT 1;





-- PROBLEM-2: What % of SKUs have generated some revenue in this time period?

set @zero = (select count(SKU_NAME) FROM (SELECT SKU_NAME, SUM(ORDERED_REVENUE) AS Revenue FROM sales_data GROUP BY 1 HAVING Revenue = 0 ) t );
set @positive = (select count(SKU_NAME) FROM (SELECT SKU_NAME, SUM(ORDERED_REVENUE) AS Revenue FROM sales_data GROUP BY 1 HAVING Revenue > 0) t );
set @percent = Round((((select @positive)/((select @positive) + (select @zero)))*100),2);
select @percent;



-- EXTRA: SKUs that stopped selling completely after July

select 
	SKU_NAME, 
    SUM(CASE WHEN MONTH(FEED_DATE) = 5 THEN ORDERED_UNITS ELSE 0 END) AS May_units,
    SUM(CASE WHEN MONTH(FEED_DATE) = 6 THEN ORDERED_UNITS ELSE 0 END) AS June_units,
    SUM(CASE WHEN MONTH(FEED_DATE) = 7 THEN ORDERED_UNITS ELSE 0 END) AS July_units,
    SUM(CASE WHEN MONTH(FEED_DATE) = 8 THEN ORDERED_UNITS ELSE 0 END) AS Aug_units
from sales_data
GROUP BY 1
having July_units = 0 and Aug_units = 0
order by 1;




-- PROBLEM-3: Somewhere in this timeframe, there was a Sale Event. Identify the dates.

select 
	FEED_DATE, 
    sum(VIEWS) as total_views, 
    sum(UNITS) as total_units 
from glance_views
group by 1
order by 2 DESC
limit 10;



-- Average daily units sold BEFORE sale event

select avg(daily_units_before) from
(
SELECT 
   FEED_DATE,
   SUM(UNITS) AS daily_units_before
FROM glance_views
WHERE FEED_DATE < '2019-07-15'
GROUP BY 1) t;

-- Average daily units sold AFTER sale event
 
select avg(daily_units_after) from
(
SELECT 
	FEED_DATE,
	SUM(UNITS) AS daily_units_after
FROM glance_views
WHERE FEED_DATE > '2019-07-15'
GROUP BY 1
) t;




-- PROBLEM-5: In each category, find the subcategory that has grown slowest relative to the category it is present in. If you were 
-- handling the entire portfolio, which of these subcategories would you be most concerned with?




WITH subcategory_monthly_revenue AS (
	SELECT 
		CATEGORY, 
		SUB_CATEGORY,
		SUM(CASE WHEN MONTH(FEED_DATE) = 5 THEN ORDERED_REVENUE ELSE 0 END) AS May_revenue,
		SUM(CASE WHEN MONTH(FEED_DATE) = 6 THEN ORDERED_REVENUE ELSE 0 END) AS June_revenue,
		SUM(CASE WHEN MONTH(FEED_DATE) = 7 THEN ORDERED_REVENUE ELSE 0 END) AS July_revenue,
		SUM(CASE WHEN MONTH(FEED_DATE) = 8 THEN ORDERED_REVENUE ELSE 0 END) AS Aug_revenue
	FROM sales_data
	GROUP BY CATEGORY, SUB_CATEGORY
),
category_monthly_revenue AS (
	SELECT 
		CATEGORY, 
		SUM(CASE WHEN MONTH(FEED_DATE) = 5 THEN ORDERED_REVENUE ELSE 0 END) AS May_revenue,
		SUM(CASE WHEN MONTH(FEED_DATE) = 6 THEN ORDERED_REVENUE ELSE 0 END) AS June_revenue,
		SUM(CASE WHEN MONTH(FEED_DATE) = 7 THEN ORDERED_REVENUE ELSE 0 END) AS July_revenue,
		SUM(CASE WHEN MONTH(FEED_DATE) = 8 THEN ORDERED_REVENUE ELSE 0 END) AS Aug_revenue
	FROM sales_data
	GROUP BY CATEGORY
),
category_growth AS (
	SELECT 
		CATEGORY,
		CASE WHEN May_revenue = 0 THEN NULL 
			ELSE (June_revenue - May_revenue) / May_revenue 
		END AS may_june_growth,
		
		CASE WHEN June_revenue = 0 THEN NULL 
			ELSE (July_revenue - June_revenue) / June_revenue 
		END AS june_july_growth,
		
		CASE WHEN July_revenue = 0 THEN NULL 
			ELSE (Aug_revenue - July_revenue) / July_revenue 
		END AS july_aug_growth
	FROM category_monthly_revenue
),
subcategory_growth AS (
	SELECT 
		CATEGORY,
		SUB_CATEGORY,
		CASE WHEN May_revenue = 0 THEN NULL 
			ELSE (June_revenue - May_revenue) / May_revenue 
		END AS may_june_growth,
		
		CASE WHEN June_revenue = 0 THEN NULL 
			ELSE (July_revenue - June_revenue) / June_revenue 
		END AS june_july_growth,
		
		CASE WHEN July_revenue = 0 THEN NULL 
			ELSE (Aug_revenue - July_revenue) / July_revenue 
		END AS july_aug_growth
	FROM subcategory_monthly_revenue
),
subcategory_average_growth as
(
	SELECT 
		CATEGORY,
		SUB_CATEGORY,
		(COALESCE(may_june_growth, 0) + COALESCE(june_july_growth, 0) + COALESCE(july_aug_growth, 0)) / 3 AS subcategory_avg_growth_rate
	FROM subcategory_growth
),
category_average_growth as
(
	SELECT 
		CATEGORY,
		(COALESCE(may_june_growth, 0) + COALESCE(june_july_growth, 0) + COALESCE(july_aug_growth, 0)) / 3 AS category_avg_growth_rate
	FROM category_growth
),
final_table as
(
select 
	t1.CATEGORY,
    t1.SUB_CATEGORY,
    round(t1.subcategory_avg_growth_rate,2) as subcategory_avg_growth_rate ,
    round(t2.category_avg_growth_rate,2) as category_avg_growth_rate,
    rank() over(partition by CATEGORY order by round(t1.subcategory_avg_growth_rate,2) ASC) as rnk
from subcategory_average_growth as t1
join category_average_growth as t2
on t1.CATEGORY = t2.CATEGORY
)

select CATEGORY,SUB_CATEGORY,subcategory_avg_growth_rate,category_avg_growth_rate
from final_table
where rnk=1;




-- PROBLEM-7: For SKU Name C120[H:8NV, discuss whether Unit Conversion (Units/Views) is affected by Average Selling Price.

select t1.FEED_DATE, t1.SKU_NAME, t1.avg_selling_price, t2.unit_conversion
from
(
	select FEED_DATE, SKU_NAME, sum(ORDERED_REVENUE)/sum(ORDERED_UNITS) as avg_selling_price
	from sales_data 
	group by 1,2
    having SKU_NAME = 'C120[H:8NV'
) as t1
inner join
(
	select FEED_DATE, SKU_NAME, sum(VIEWS)/sum(UNITS) as unit_conversion
	from glance_views
	group by 1,2
	having SKU_NAME = 'C120[H:8NV'
) as t2
on t1.FEED_DATE = t2.FEED_DATE;


-- EXTRA-1:  Estimate the revenue that could have been earned if the product wasn't out of stock during some views.

with merged as
(
select 
	t1.SKU_NAME, 
    t1.FEED_DATE, 
    t1.CATEGORY, 
    t1.SUB_CATEGORY, 
    t1.ORDERED_REVENUE, 
    t1.ORDERED_UNITS, 
    t1.REP_OOS, 
    t2.VIEWS, 
    (t2.UNITS/t2.VIEWS) as UNIT_CONVERSION,  
    (t1.ORDERED_REVENUE/t1.ORDERED_UNITS) as avg_selling_price
from sales_data as t1
inner join glance_views as t2
on t1.SKU_NAME = t2.SKU_NAME and t1.FEED_DATE = t2.FEED_DATE
)
select SKU_NAME, round(sum(lost_sales),2) as lost_sales 
from
(
select SKU_NAME, FEED_DATE, (VIEWS)*(UNIT_CONVERSION)*(REP_OOS)*(avg_selling_price) as lost_sales
from merged
) as t
group by 1
order by 2 DESC;

