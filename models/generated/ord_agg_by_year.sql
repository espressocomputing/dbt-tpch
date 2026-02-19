{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:7', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    date_trunc('year', order_date),
    count(*) as cnt, sum(order_amount) as total_amount
from {{ ref('orders') }}
group by 1, 2

-- sf={{ var('sf', '10') }}
