{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_date_1996') }} limit 1)

select
    date_trunc('month', o.order_date) as month,
    count(*) as cnt,
    sum(o.order_amount) as total_amount
from {{ ref('ord_full_scan') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where o.order_priority_code = '3-MEDIUM'
    and c.customer_market_segment_name = 'FURNITURE'
group by 1

-- sf={{ var('sf', '10') }}
