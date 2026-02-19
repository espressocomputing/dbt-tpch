{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+parts+suppliers', 'joins:2', 'agg:none', 'rows_sf1:6M', 'cols:10', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount, oi.discount_percentage,
    p.part_name, p.part_brand_name, p.part_type_name,
    s.supplier_name, s.nation_key
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key

) _q