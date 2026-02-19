{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('join_oi_reg_america_agg_1996') }} limit 1)

select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where c.customer_market_segment_name = 'FURNITURE'
group by 1

-- sf={{ var('sf', '10') }}
