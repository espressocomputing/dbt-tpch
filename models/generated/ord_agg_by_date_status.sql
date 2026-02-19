{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:5K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_date, order_status_code,
    count(*) as cnt, sum(order_amount) as total_amount
from {{ ref('orders') }}
group by 1, 2

) _q