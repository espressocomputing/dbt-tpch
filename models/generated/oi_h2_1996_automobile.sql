{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:none', 'rows_sf1:180K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('ord_prio_1_urgent_seg_furniture') }} limit 1)

select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount
from {{ ref('tbl_oi_rail') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.order_date >= '1996-07-01' and oi.order_date <= '1996-12-31'
    and c.customer_market_segment_name = 'AUTOMOBILE'

-- sf={{ var('sf', '10') }}
