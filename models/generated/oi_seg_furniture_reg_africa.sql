{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:none', 'rows_sf1:240K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand21_1992') }} limit 1)

select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount, oi.quantity
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where c.customer_market_segment_name = 'FURNITURE'
    and r.region_name = 'AFRICA'

-- sf={{ var('sf', '10') }}
