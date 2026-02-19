{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:1.5M', 'cols:8', 'filter:none', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_clerk_name, shipping_priority, order_amount
from {{ ref('orders') }}

) _q