{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(order_amount) as total_amount
from {{ ref('orders') }}
where order_priority_code = '4-NOT SPECIFIED'
group by 1

-- sf={{ var('sf', '10') }}
