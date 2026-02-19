{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, supplier_key as dim_key, discount_percentage as measure,
    percent_rank() over (partition by supplier_key order by discount_percentage) as pct_rank,
    cume_dist() over (partition by supplier_key order by discount_percentage) as cum_dist
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
