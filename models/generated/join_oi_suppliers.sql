{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+suppliers', 'joins:1', 'agg:none', 'rows_sf1:6M', 'cols:9', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.customer_key, oi.part_key,
    oi.quantity, oi.gross_item_sales_amount,
    s.supplier_name, s.nation_key, s.supplier_account_balance
from {{ ref('oi_full_scan') }} oi
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key

-- sf={{ var('sf', '10') }}
