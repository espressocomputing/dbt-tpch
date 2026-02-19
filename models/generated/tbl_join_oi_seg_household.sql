{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:none', 'rows_sf1:1.2M', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount, oi.discount_percentage
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where c.customer_market_segment_name = 'HOUSEHOLD'

-- sf={{ var('sf', '10') }}
