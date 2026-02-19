{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:125K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand22_1994') }} limit 1)

select
    order_item_key, order_date, customer_key, quantity,
    gross_item_sales_amount
from {{ ref('orders_items') }}
where order_date >= '1993-07-01' and order_date <= '1993-12-31'
    and ship_mode_name = 'MAIL'

-- sf={{ var('sf', '10') }}
