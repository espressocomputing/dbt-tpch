{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(order_amount) as total_amount
from {{ ref('ord_full_scan') }}
where order_priority_code = '1-URGENT'
group by 1

) _q