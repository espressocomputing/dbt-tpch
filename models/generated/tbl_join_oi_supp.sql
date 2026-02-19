{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+suppliers', 'joins:1', 'agg:none', 'rows_sf1:6M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount,
    s.supplier_name, s.nation_key
from {{ ref('orders_items') }} oi
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key

-- sf={{ var('sf', '10') }}
