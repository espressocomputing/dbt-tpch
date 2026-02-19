{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts+suppliers+nations+regions', 'joins:4', 'agg:simple', 'rows_sf1:5250', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    r.region_name,
    p.part_type_name,
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.quantity) as avg_qty
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1, 2, 3

-- sf={{ var('sf', '10') }}
