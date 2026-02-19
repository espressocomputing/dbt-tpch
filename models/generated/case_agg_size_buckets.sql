{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_ship_air_reg_america') }} limit 1)

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
from {{ ref('ord_priority_4_not_specified') }}
group by 1

-- sf={{ var('sf', '10') }}
