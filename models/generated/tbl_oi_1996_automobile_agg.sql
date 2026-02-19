{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:simple', 'rows_sf1:12', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('oi_filter_rail_ship') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.order_date >= '1996-01-01' and oi.order_date <= '1996-12-31'
    and c.customer_market_segment_name = 'AUTOMOBILE'
group by 1

-- sf={{ var('sf', '10') }}
