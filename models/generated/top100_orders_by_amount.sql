{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:100', 'cols:4', 'filter:heavy', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
order by order_amount desc
limit 100

-- sf={{ var('sf', '10') }}
