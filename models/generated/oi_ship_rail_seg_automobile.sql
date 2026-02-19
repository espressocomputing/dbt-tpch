{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:none', 'rows_sf1:170K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_ship_truck_seg_household') }} limit 1)

select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount
from {{ ref('oi_filter_high_value') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.ship_mode_name = 'RAIL'
    and c.customer_market_segment_name = 'AUTOMOBILE'

-- sf={{ var('sf', '10') }}
