{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:5K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_h1_1996_air') }} limit 1)

select
    supplier_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {{ ref('oi_full_scan') }}
group by 1
having count(*) > 500

-- sf={{ var('sf', '10') }}
