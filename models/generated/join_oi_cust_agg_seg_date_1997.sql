{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    c.customer_market_segment_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.order_date >= '1997-01-01' and oi.order_date <= '1997-12-31'
group by 1

-- sf={{ var('sf', '10') }}
