{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+parts', 'joins:1', 'agg:simple', 'rows_sf1:25', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_ship_fob_reg_africa') }} limit 1)

select
    p.part_brand_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
group by 1

-- sf={{ var('sf', '10') }}
