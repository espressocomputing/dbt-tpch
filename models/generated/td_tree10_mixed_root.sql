{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select customer_key, order_key, gross_item_sales_amount, order_date
from {{ ref('orders_items') }}
where order_date > '1996-01-01'
