{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
where order_priority_code = '1-URGENT'
    and order_date >= '1995-01-01' and order_date <= '1995-12-31'

-- sf={{ var('sf', '10') }}
