{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+suppliers', 'joins:1', 'agg:multi', 'rows_sf1:10K', 'cols:7', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('join_oi_reg_africa_agg_1997') }} limit 1),
supplier_sales as (
    select
        supplier_key,
        sum(gross_item_sales_amount) as total_sales,
        count(*) as item_count,
        avg(discount_percentage) as avg_discount
    from {{ ref('oi_full_scan') }}
    group by 1
)
select
    s.supplier_key, s.supplier_name, s.nation_key,
    ss.total_sales, ss.item_count, ss.avg_discount,
    rank() over (order by ss.total_sales desc) as sales_rank
from {{ ref('suppliers') }} s
join supplier_sales ss on s.supplier_key = ss.supplier_key

) _q