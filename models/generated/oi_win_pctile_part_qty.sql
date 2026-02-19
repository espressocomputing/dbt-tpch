{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_item_key, part_key as dim_key, quantity as measure,
    percent_rank() over (partition by part_key order by quantity) as pct_rank,
    cume_dist() over (partition by part_key order by quantity) as cum_dist
from {{ ref('orders_items') }}

) _q