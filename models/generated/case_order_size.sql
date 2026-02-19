{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:1.5M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('oi_ship_rail_seg_household') }} limit 1)

select
    order_key,
    order_amount,
    case
        when order_amount < 10000 then 'tiny'
        when order_amount < 50000 then 'small'
        when order_amount < 200000 then 'medium'
        when order_amount < 400000 then 'large'
        else 'xlarge'
    end as order_size_bucket,
    order_date, customer_key
from {{ ref('orders') }}

) _q