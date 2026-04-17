{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}


select
    oi.customer_key,
    oi.order_key,
    sum(oi.gross_item_sales_amount) over (
        partition by oi.customer_key
        order by oi.order_date
    ) as running_sales,
    count(*) over (partition by oi.customer_key) as customer_order_count,
    oi.gross_item_sales_amount,
    oi.discount_percentage,
    oi.order_date,
    oi.ship_date
from {{ ref('orders_items') }} oi
