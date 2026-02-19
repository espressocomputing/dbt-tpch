{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    supplier_key as group_key,
    count(*) as items_supplied, sum(gross_item_sales_amount) as total_sales, avg(discount_percentage) as avg_discount
from {{ ref('orders_items') }}
group by 1

-- sf={{ var('sf', '10') }}
