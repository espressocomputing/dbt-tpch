{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_ship_rail_reg_africa') }} limit 1)

select
    supplier_key as group_key,
    count(*) as items_supplied, sum(gross_item_sales_amount) as total_sales, avg(discount_percentage) as avg_discount
from {{ ref('oi_date_h1_1996') }}
group by 1

-- sf={{ var('sf', '10') }}
