{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:100K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    customer_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    sum(quantity) as total_qty
from {{ ref('oi_full_scan') }}
where order_date >= '1996-01-01' and order_date <= '1996-12-31'
group by 1

-- sf={{ var('sf', '10') }}
