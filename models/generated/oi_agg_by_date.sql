{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:2500', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_date as group_key,
    count(*) as cnt, sum(gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }}
group by 1

-- sf={{ var('sf', '10') }}
