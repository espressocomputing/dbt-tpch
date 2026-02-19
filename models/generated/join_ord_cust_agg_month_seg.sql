{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:simple', 'rows_sf1:420', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_1995_building_agg') }} limit 1)

select
    date_trunc('month', o.order_date) as month,
    c.customer_market_segment_name,
    count(*) as order_count,
    sum(o.order_amount) as total_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
group by 1, 2

-- sf={{ var('sf', '10') }}
