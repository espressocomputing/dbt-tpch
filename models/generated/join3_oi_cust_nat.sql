{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers+nations', 'joins:2', 'agg:none', 'rows_sf1:6M', 'cols:6', 'filter:none', 'sample', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount,
    c.customer_market_segment_name,
    n.nation_name
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key

-- sf={{ var('sf', '10') }}
