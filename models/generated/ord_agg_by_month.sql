{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    date_trunc('month', order_date) as group_key,
    count(*) as cnt, sum(order_amount) as total_amount, avg(order_amount) as avg_amount
from {{ ref('ord_full_scan') }}
group by 1

-- sf={{ var('sf', '10') }}
