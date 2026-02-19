{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+suppliers+nations+regions', 'joins:3', 'agg:none', 'rows_sf1:1.2M', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    s.supplier_name
from {{ ref('orders_items') }} oi
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where r.region_name = 'AMERICA'

-- sf={{ var('sf', '10') }}
