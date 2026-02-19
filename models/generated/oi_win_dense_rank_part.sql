{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, part_key, supplier_key, quantity,
    dense_rank() over (partition by part_key order by quantity desc) as qty_rank,
    percent_rank() over (partition by part_key order by gross_item_sales_amount) as pct_rank
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
