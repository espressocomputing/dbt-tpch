{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:window', 'rows_sf1:1.5M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_key, order_date, order_amount,
    avg(order_amount) over (order by order_date rows between 999 preceding and current row) as moving_avg_1000,
    count(*) over (order by order_date rows between 999 preceding and current row) as window_size
from {{ ref('orders') }}

) _q