{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:125K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('oi_h1_1997_air') }} limit 1)

select
    order_item_key, order_date, customer_key, quantity,
    gross_item_sales_amount
from {{ ref('oi_full_scan') }}
where order_date >= '1995-07-01' and order_date <= '1995-12-31'
    and ship_mode_name = 'REG AIR'

) _q