{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:none', 'rows_sf1:170K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_brand_brand55') }} limit 1)

select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.ship_mode_name = 'REG AIR'
    and c.customer_market_segment_name = 'BUILDING'

-- sf={{ var('sf', '10') }}
