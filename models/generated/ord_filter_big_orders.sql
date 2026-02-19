{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:30K', 'cols:6', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_amount
from {{ ref('orders') }}
where order_amount > 400000

-- sf={{ var('sf', '10') }}
