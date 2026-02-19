{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    c.customer_market_segment_name,
    count(*) as order_count,
    sum(o.order_amount) as total_amount,
    avg(o.order_amount) as avg_amount
from {{ ref('ord_date_1994') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
group by 1

-- sf={{ var('sf', '10') }}
