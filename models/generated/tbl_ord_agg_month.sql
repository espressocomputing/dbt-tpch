{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select date_trunc('month', order_date) as month, count(*) as cnt, sum(order_amount) as total_amount
from {{ ref('ord_date_1998') }}
group by 1

-- sf={{ var('sf', '10') }}
