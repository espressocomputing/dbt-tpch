{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:200K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select part_key, count(*) as times_ordered, sum(quantity) as total_qty, avg(base_price) as avg_price, sum(gross_item_sales_amount) as total_revenue
from {{ ref('orders_items') }}
group by part_key

-- sf={{ var('sf', '10') }}
