{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:600K', 'cols:10', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, order_key, order_date, customer_key,
    part_key, supplier_key, quantity, base_price,
    gross_item_sales_amount, net_item_sales_amount
from {{ ref('orders_items') }}
where discount_percentage > 0.08

-- sf={{ var('sf', '10') }}
