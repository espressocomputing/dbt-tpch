{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts+suppliers+nations+regions', 'joins:4', 'agg:none', 'rows_sf1:6M', 'cols:8', 'filter:none', 'sample', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount,
    p.part_brand_name, p.part_type_name,
    s.supplier_name,
    n.nation_name, r.region_name
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key

-- sf={{ var('sf', '10') }}
