{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    case
        when order_amount < 10000 then 'tiny'
        when order_amount < 50000 then 'small'
        when order_amount < 200000 then 'medium'
        when order_amount < 400000 then 'large'
        else 'xlarge'
    end as size_bucket,
    count(*) as order_count,
    sum(order_amount) as total_amount,
    avg(order_amount) as avg_amount
from {{ ref('orders') }}
group by 1

) _q