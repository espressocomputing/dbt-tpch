{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:750K', 'cols:10', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, order_key, order_date, customer_key,
    part_key, supplier_key, quantity, base_price,
    gross_item_sales_amount, net_item_sales_amount
from {{ ref('oi_date_h2_1994') }}
where return_status_code = 'R' and order_status_code = 'F'

-- sf={{ var('sf', '10') }}
