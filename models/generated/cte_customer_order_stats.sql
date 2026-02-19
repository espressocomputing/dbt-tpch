{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:simple', 'rows_sf1:150K', 'cols:10', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with order_stats as (
    select
        customer_key,
        count(*) as order_count,
        sum(order_amount) as total_amount,
        min(order_date) as first_order,
        max(order_date) as last_order,
        datediff(day, min(order_date), max(order_date)) as tenure_days
    from {{ ref('orders') }}
    group by 1
)
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    c.customer_account_balance,
    os.order_count, os.total_amount, os.first_order, os.last_order,
    os.tenure_days,
    os.total_amount / nullif(os.order_count, 0) as avg_order_value
from {{ ref('customers') }} c
join order_stats os on c.customer_key = os.customer_key

-- sf={{ var('sf', '10') }}
