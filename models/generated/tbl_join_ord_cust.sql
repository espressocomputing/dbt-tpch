{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:1.5M', 'cols:5', 'filter:none', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_market_segment_name
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key

-- sf={{ var('sf', '10') }}
