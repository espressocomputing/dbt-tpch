{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select order_key, customer_key, total_price from {{ ref('orders') }}
) _q