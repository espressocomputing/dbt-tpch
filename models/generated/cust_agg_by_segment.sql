{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:simple', 'rows_sf1:5', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    customer_market_segment_name as group_key,
    count(*) as cnt, avg(customer_account_balance) as avg_balance, sum(customer_account_balance) as total_balance
from {{ ref('cust_full_scan') }}
group by 1

) _q