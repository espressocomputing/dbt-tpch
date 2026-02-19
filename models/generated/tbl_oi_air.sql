{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:860K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, order_key, order_date, customer_key,
    quantity, gross_item_sales_amount
from {{ ref('orders_items') }}
where ship_mode_name = 'AIR'

-- sf={{ var('sf', '10') }}
