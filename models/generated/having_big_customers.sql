{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:50K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    customer_key,
    count(*) as order_count,
    sum(gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }}
group by 1
having count(*) > 100

-- sf={{ var('sf', '10') }}
