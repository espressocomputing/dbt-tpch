{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select customer_key, order_key, gross_item_sales_amount, order_date
from {{ ref('orders_items') }} where order_date > '1997-01-01'
