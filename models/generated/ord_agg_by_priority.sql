{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('join_ord_seg_building') }} limit 1)

select
    order_priority_code as group_key,
    count(*) as cnt, sum(order_amount) as total_amount
from {{ ref('orders') }}
group by 1

-- sf={{ var('sf', '10') }}
