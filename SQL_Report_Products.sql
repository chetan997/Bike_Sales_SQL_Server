/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: report_products
-- =============================================================================

	create view report_products as
	with base_query as
	(

	/*------------------------------------------------------------------------------------------------------------------------------------------
	1) Base Query - We have to first retreive all the important columns from fact sales and dim products table to do further aggregations and analysis
	--------------------------------------------------------------------------------------------------------------------------------------------------*/
	select
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost,
		f.customer_key,
		f.sales_amount,
		f.quantity,
		f.order_date,
		f.order_number
	from [gold.fact_sales] f
	left join [gold.dim_products] p
	on f.product_key=p.product_key
	where order_date is not null -- We have to only consider the valid order date because our data is having null order dates too
	),
	product_aggregation as
	(
	/*-------------------------------------------------------------------------------------------------------------------------------------------------------------
	2) Product Aggregation - Summarizes the key matrics at product level
	--------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	select
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		count(distinct order_number) as total_orders,
		sum(sales_amount) as total_sales,
		sum(quantity) as total_quantity_sold,
		count(distinct customer_key) as total_customers,
		max(order_date) as last_order_date,
		datediff(month,min(order_date),max(order_date)) as life_span,
		round(avg(cast(sales_amount as float)/nullif(quantity,0)),1) as avg_selling_price
	from base_query
	group by product_key,
	product_name,
	category,
	subcategory,
	cost
	)
	/*----------------------------------------------------------------------------------------------------------------------------------------------------------------
	3) Final Query -  Combining all products query into one output
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	select
		product_key,
		product_name,
		category,
		subcategory,
		cost,
	--------------------------------------------------------
	---Segmenting Products on the basis of their revenue
			case when total_sales>50000 then 'High-Perfomers'
				when total_sales>=10000 then 'Mid-Performers'
				else 'Low-Perfomers'
			end Product_segment,
	--------------------------------------------------------
	   datediff(month,last_order_Date,getdate()) as Recency,
	--------------------------------------------------------
	---Average Order Revenue (AOR)
		case when total_Sales=0 then 0
			else total_Sales/total_orders
		end Avg_Order_Revenue,
	--------------------------------------------------------
	--------------------------------------------------------
	---Average Monthly Spend
		case when life_span=0 then 0
			 else total_sales/life_span
		end Avg_monthly_spend,
	--------------------------------------------------------
		total_orders,
		total_sales,
		total_quantity_sold,
		total_customers,
		last_order_date,
		life_span,
		avg_selling_price
	from product_aggregation
------------------------------------------------------------

-----To view product report output
select
*
from report_products
------------------------------------------------------------