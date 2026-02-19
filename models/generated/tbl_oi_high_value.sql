{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:600K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select order_item_key, order_key, customer_key, part_key, gross_item_sales_amount
from {{ ref('orders_items') }}
where gross_item_sales_amount > 50000

-- sf={{ var('sf', '10') }}
