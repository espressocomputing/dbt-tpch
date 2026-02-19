{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:none', 'rows_sf1:900K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_date_1996') }} limit 1)

select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    c.customer_name, c.customer_market_segment_name
from {{ ref('oi_date_1992') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.order_date >= '1995-01-01' and oi.order_date <= '1995-12-31'

-- sf={{ var('sf', '10') }}
