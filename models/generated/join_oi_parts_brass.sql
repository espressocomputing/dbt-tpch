{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts', 'joins:1', 'agg:none', 'rows_sf1:750K', 'cols:7', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('parts_filter_large') }} limit 1)

select
    oi.order_item_key, oi.order_date, oi.quantity, oi.gross_item_sales_amount,
    p.part_name, p.part_type_name, p.retail_price
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
where p.part_type_name like '%BRASS%'

-- sf={{ var('sf', '10') }}
