{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:10K', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select supplier_key, count(*) as items_supplied, sum(gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }}
group by supplier_key

) _q