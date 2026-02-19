{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:100', 'cols:6', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, order_key, part_key, supplier_key,
    gross_item_sales_amount, quantity
from {{ ref('oi_full_scan') }}
order by gross_item_sales_amount desc
limit 100

-- sf={{ var('sf', '10') }}
