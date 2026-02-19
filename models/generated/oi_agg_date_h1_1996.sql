{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:100K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_africa_1993') }} limit 1)

select
    customer_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {{ ref('orders_items') }}
where order_date >= '1996-01-01' and order_date <= '1996-06-30'
group by 1

-- sf={{ var('sf', '10') }}
