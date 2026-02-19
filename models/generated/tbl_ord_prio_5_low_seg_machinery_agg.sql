{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('oi_h2_1995_mail') }} limit 1)

select
    date_trunc('month', o.order_date) as month,
    count(*) as cnt,
    sum(o.order_amount) as total_amount
from {{ ref('ord_full_scan') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where o.order_priority_code = '5-LOW'
    and c.customer_market_segment_name = 'MACHINERY'
group by 1

) _q