{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts+suppliers+nations', 'joins:3', 'agg:simple', 'rows_sf1:625', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    n.nation_name,
    p.part_brand_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
group by 1, 2

-- sf={{ var('sf', '10') }}
