{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+suppliers', 'joins:1', 'agg:simple', 'rows_sf1:25', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('ord_date_1995') }} limit 1)

select
    s.nation_key,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
group by 1

) _q