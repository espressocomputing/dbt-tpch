{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:150K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select customer_key, count(*) as order_count, sum(order_amount) as total_spent, min(order_date) as first_order, max(order_date) as last_order
from {{ ref('orders') }}
group by customer_key

-- sf={{ var('sf', '10') }}
