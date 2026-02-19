{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('oi_1995_fob') }} limit 1)

select date_trunc('month', order_date) as month, count(*) as cnt, sum(order_amount) as total_amount
from {{ ref('orders') }}
group by 1

) _q