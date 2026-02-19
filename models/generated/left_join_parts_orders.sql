{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts+orders_items', 'joins:1', 'agg:simple', 'rows_sf1:200K', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_europe_1993') }} limit 1)

select
    p.part_key, p.part_name, p.part_brand_name, p.retail_price,
    count(oi.order_item_key) as times_ordered,
    coalesce(sum(oi.quantity), 0) as total_qty
from {{ ref('parts') }} p
left join {{ ref('orders_items') }} oi on p.part_key = oi.part_key
group by 1, 2, 3, 4

-- sf={{ var('sf', '10') }}
