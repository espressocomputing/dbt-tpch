{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}


select order_key, customer_key, order_date, order_amount
from {{ ref('orders') }}
