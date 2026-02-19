{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_status_code as group_key,
    count(*) as cnt, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }}
group by 1

) _q