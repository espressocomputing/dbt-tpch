{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:multi', 'rows_sf1:7', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with yearly as (
    select
        date_trunc('year', order_date) as year,
        count(*) as item_count,
        sum(gross_item_sales_amount) as total_sales,
        sum(quantity) as total_qty
    from {{ ref('orders_items') }}
    group by 1
)
select
    year,
    item_count,
    total_sales,
    total_qty,
    lag(total_sales) over (order by year) as prev_year_sales,
    total_sales - lag(total_sales) over (order by year) as yoy_change
from yearly

) _q