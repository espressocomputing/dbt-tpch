{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:none', 'rows_sf1:900K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    c.customer_name, c.customer_market_segment_name
from {{ ref('oi_full_scan') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.order_date >= '1995-01-01' and oi.order_date <= '1995-12-31'

) _q