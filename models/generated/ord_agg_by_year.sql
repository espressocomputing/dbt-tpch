{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:7', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('join_oi_cust_reg_africa') }} limit 1)

select
    date_trunc('year', order_date) as group_key,
    count(*) as cnt, sum(order_amount) as total_amount
from {{ ref('orders') }}
group by 1

-- sf={{ var('sf', '10') }}
