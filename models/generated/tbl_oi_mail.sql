{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:860K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, order_key, order_date, customer_key,
    quantity, gross_item_sales_amount
from {{ ref('oi_date_1994') }}
where ship_mode_name = 'MAIL'

-- sf={{ var('sf', '10') }}
