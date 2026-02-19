{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:window', 'rows_sf1:1.5M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_key, customer_key, order_date, order_amount,
    row_number() over (partition by customer_key order by order_date) as order_seq,
    sum(order_amount) over (partition by customer_key order by order_date rows unbounded preceding) as cumulative_spend
from {{ ref('orders') }}
{% if is_incremental() %}
  where order_date > (select max(order_date) from {{ this }})
{% endif %}

) _q