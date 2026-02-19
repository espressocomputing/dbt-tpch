{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+parts+suppliers', 'joins:2', 'agg:simple', 'rows_sf1:625', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    p.part_brand_name,
    s.nation_key,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    sum(oi.quantity) as total_qty
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
group by 1, 2

) _q