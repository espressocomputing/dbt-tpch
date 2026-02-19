{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:7', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_seg_building_reg_europe') }} limit 1)

select ship_mode_name, count(*) as cnt, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales
from {{ ref('oi_full_scan') }}
group by ship_mode_name

-- sf={{ var('sf', '10') }}
