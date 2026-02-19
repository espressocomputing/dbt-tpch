{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:6M', 'cols:10', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select order_item_key, order_key, order_date, customer_key, part_key, supplier_key, quantity, base_price, gross_item_sales_amount, net_item_sales_amount
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
