{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:750K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('join_oi_parts_brass') }} limit 1)

select order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
where order_status_code = 'F'

) _q