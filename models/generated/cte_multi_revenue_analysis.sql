{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:multi', 'rows_sf1:5', 'cols:7', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with customer_revenue as (
    select customer_key, sum(gross_item_sales_amount) as revenue
    from {{ ref('orders_items') }}
    group by 1
),
segment_stats as (
    select
        c.customer_market_segment_name,
        count(*) as customer_count,
        sum(cr.revenue) as segment_revenue,
        avg(cr.revenue) as avg_revenue,
        min(cr.revenue) as min_revenue,
        max(cr.revenue) as max_revenue
    from {{ ref('customers') }} c
    join customer_revenue cr on c.customer_key = cr.customer_key
    group by 1
)
select
    customer_market_segment_name,
    customer_count,
    segment_revenue,
    avg_revenue,
    min_revenue,
    max_revenue,
    segment_revenue / nullif(sum(segment_revenue) over (), 0) as revenue_share
from segment_stats

) _q