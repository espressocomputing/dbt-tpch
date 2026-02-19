{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:simple', 'rows_sf1:50K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with customer_spend as (
    select
        customer_key,
        sum(gross_item_sales_amount) as total_spend,
        count(*) as item_count
    from {{ ref('orders_items') }}
    group by 1
)
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    cs.total_spend, cs.item_count
from {{ ref('customers') }} c
join customer_spend cs on c.customer_key = cs.customer_key
where cs.total_spend > 1000000

) _q