{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+suppliers', 'joins:1', 'agg:multi', 'rows_sf1:10K', 'cols:10', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with supplier_items as (
    select
        supplier_key,
        count(*) as item_count,
        sum(gross_item_sales_amount) as total_sales,
        avg(discount_percentage) as avg_discount,
        sum(case when return_status_code = 'R' then 1 else 0 end) as return_count
    from {{ ref('orders_items') }}
    group by 1
),
supplier_detail as (
    select
        s.supplier_key, s.supplier_name, s.nation_key,
        si.item_count, si.total_sales, si.avg_discount, si.return_count,
        si.return_count::float / nullif(si.item_count, 0) as return_rate
    from {{ ref('suppliers') }} s
    join supplier_items si on s.supplier_key = si.supplier_key
)
select
    supplier_key, supplier_name, nation_key,
    item_count, total_sales, avg_discount, return_count, return_rate,
    rank() over (order by total_sales desc) as sales_rank,
    rank() over (order by return_rate) as quality_rank
from supplier_detail

-- sf={{ var('sf', '10') }}
