{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+parts', 'joins:1', 'agg:simple', 'rows_sf1:150', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    p.part_type_name,
    count(*) as item_count,
    sum(oi.quantity) as total_qty,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('oi_full_scan') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
group by 1

) _q