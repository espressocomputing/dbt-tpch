{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:simple', 'rows_sf1:150K', 'cols:7', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with order_stats as (
    select
        customer_key,
        count(*) as order_count,
        sum(order_amount) as total_amount,
        min(order_date) as first_order,
        max(order_date) as last_order
    from {{ ref('orders') }}
    group by 1
)
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    os.order_count, os.total_amount, os.first_order, os.last_order
from {{ ref('customers') }} c
join order_stats os on c.customer_key = os.customer_key

) _q