{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:window', 'rows_sf1:1.5M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_1998_automobile') }} limit 1)

select
    order_key, customer_key, order_date, order_amount,
    row_number() over (partition by customer_key order by order_date) as order_seq,
    sum(order_amount) over (partition by customer_key order by order_date rows unbounded preceding) as cumulative_spend
from {{ ref('orders') }}

-- sf={{ var('sf', '10') }}
