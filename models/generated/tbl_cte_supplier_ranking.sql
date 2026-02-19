{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+suppliers', 'joins:1', 'agg:multi', 'rows_sf1:10K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with supplier_sales as (
    select
        supplier_key,
        sum(gross_item_sales_amount) as total_sales,
        count(*) as item_count
    from {{ ref('orders_items') }}
    group by 1
)
select
    s.supplier_key, s.supplier_name,
    ss.total_sales, ss.item_count,
    rank() over (order by ss.total_sales desc) as sales_rank
from {{ ref('suppliers') }} s
join supplier_sales ss on s.supplier_key = ss.supplier_key

-- sf={{ var('sf', '10') }}
