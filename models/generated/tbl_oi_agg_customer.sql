{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:150K', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select customer_key, count(*) as item_count, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales, min(order_date) as first_order, max(order_date) as last_order
from {{ ref('orders_items') }}
group by customer_key

-- sf={{ var('sf', '10') }}
