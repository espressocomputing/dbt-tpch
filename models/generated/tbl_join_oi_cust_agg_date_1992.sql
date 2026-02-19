{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:simple', 'rows_sf1:5', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_1996_machinery') }} limit 1)

select
    c.customer_market_segment_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.order_date >= '1992-01-01' and oi.order_date <= '1992-12-31'
group by 1

-- sf={{ var('sf', '10') }}
