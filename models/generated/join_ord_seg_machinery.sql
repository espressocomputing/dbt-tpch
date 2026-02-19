{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:300K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand11_1995') }} limit 1)

select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where c.customer_market_segment_name = 'MACHINERY'

-- sf={{ var('sf', '10') }}
