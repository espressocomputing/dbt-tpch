{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders+customers+nations', 'joins:2', 'agg:none', 'rows_sf1:1.5M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_market_segment_name,
    n.nation_name
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key

) _q