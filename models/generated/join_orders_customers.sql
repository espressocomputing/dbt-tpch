{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:1.5M', 'cols:7', 'filter:none', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

select
    o.order_key, o.order_date, o.order_amount, o.order_status_code,
    c.customer_name, c.customer_market_segment_name, c.customer_account_balance
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key

-- sf={{ var('sf', '10') }}
