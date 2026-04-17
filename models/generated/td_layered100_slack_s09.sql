{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select order_key, customer_key, order_date, order_amount, order_priority_code from {{ ref('orders') }} limit 100000
