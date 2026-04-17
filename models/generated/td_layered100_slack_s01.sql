{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select order_key, customer_key, order_date, order_amount, order_priority_code,
       row_number() over (partition by order_key order by order_key) as rn
from {{ ref('orders') }}
