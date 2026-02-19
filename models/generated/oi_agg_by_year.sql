{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:7', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    date_trunc('year', order_date) as group_key,
    count(*) as cnt, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales
from {{ ref('tbl_oi_ship') }}
group by 1

-- sf={{ var('sf', '10') }}
