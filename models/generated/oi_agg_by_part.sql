{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:200K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    part_key as group_key,
    count(*) as times_ordered, sum(quantity) as total_qty, avg(base_price) as avg_price
from {{ ref('orders_items') }}
group by 1

-- sf={{ var('sf', '10') }}
