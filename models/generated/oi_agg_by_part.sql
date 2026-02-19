{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:200K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_oi_1994_furniture_agg') }} limit 1)

select
    part_key as group_key,
    count(*) as times_ordered, sum(quantity) as total_qty, avg(base_price) as avg_price
from {{ ref('orders_items') }}
group by 1

) _q