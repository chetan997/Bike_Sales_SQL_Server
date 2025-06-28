/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: report_customers
-- =============================================================================
create view report_customers as
with base_query as
(
/*-----------------------------------------------------------------------------------------------------------------------------------------------------
	1) Base Query - We have to first retreive all the important columns from fact sales and dim products table to do further aggregations and analysis
------------------------------------------------------------------------------------------------------------------------------------------------------*/
select
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
concat(first_name,' ',last_name) as customer_name,
datediff(year,birthdate,getdate()) as age
from [gold.fact_sales] f
left join [gold.dim_customers] c
on f.customer_key=c.customer_key
where order_date is not null -- We have to only consider the valid order date because our data is having null order dates too
)
,
customer_aggregation as 
(
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	2) Product Aggregation - Summarizes the key matrics at customer level
------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

select
customer_key,
customer_number,
customer_name,
age,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_qauntity,
count(distinct product_key) as total_products,
max(order_date) as last_order,
DATEDIFF(month,min(order_date),max(order_Date)) as lifespan
from base_query
group by customer_key,
customer_number,
customer_name,
age
)
/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	3) Final Query -  Combining all customer query into one output
--------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

select
customer_key,
customer_number,
customer_name,
age,
----------------------------------------------------------------------------------------
-----Segmenting the Age Group for better understanding
case when age<20 then 'Under 20'
	when age between 20 and 29 then '20-29'
	when age between 30 and 39 then '30-39'
	when age between 40 and 59 then '40-49'
	else '50 and Above'
end age_group,
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
----Segmenting the types of customer on the basis of theirlifespan and total sales
case when lifespan>=12 and total_sales>5000 then 'VIP'
	when lifespan>=12 and total_sales<=5000 then 'Regular'
	else 'New'
end Customer_segment,
-----------------------------------------------------------------------------------------
last_order,
datediff(month,last_order,getdate()) as recency, 
total_orders,
total_sales,
total_qauntity,
total_products,
lifespan,
-----------------------------------------------------------------------------------------
---Average Order Revenue (AOR)
case when total_sales=0 then 0
	else total_sales/total_orders
end avg_order_value,
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
----Averane Monthly Spend
case when lifespan=0 then total_Sales	
	else total_Sales/lifespan
end avg_monthly_spend
from customer_aggregation
-----------------------------------------------------------------------------------------

---To View customer report output

select
*
from report_customers
-----------------------------------------------------------------------------------------
