{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:125K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_item_key, order_date, customer_key, quantity,
    gross_item_sales_amount
from {{ ref('oi_full_scan') }}
where order_date >= '1997-01-01' and order_date <= '1997-06-30'
    and ship_mode_name = 'SHIP'

) _q