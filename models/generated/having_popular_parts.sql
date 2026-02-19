{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:50K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    part_key,
    count(*) as times_ordered,
    sum(quantity) as total_qty,
    sum(gross_item_sales_amount) as total_revenue
from {{ ref('orders_items') }}
group by 1
having sum(gross_item_sales_amount) > 500000

-- sf={{ var('sf', '10') }}
