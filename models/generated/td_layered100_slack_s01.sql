{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select order_key, customer_key, order_date, total_price, order_priority,
       row_number() over (partition by order_key order by order_key) as rn
from {{ ref('orders') }}
) _q