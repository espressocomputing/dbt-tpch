{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers+orders', 'joins:1', 'agg:none', 'rows_sf1:50K', 'cols:3', 'filter:heavy', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select c.customer_key, c.customer_name, c.customer_market_segment_name
from {{ ref('customers') }} c
where not exists (
    select 1 from {{ ref('orders') }} o where o.customer_key = c.customer_key
)

) _q