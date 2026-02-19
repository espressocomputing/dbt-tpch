{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:simple', 'rows_sf1:25', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    nation_key as group_key,
    count(*) as cnt, avg(customer_account_balance) as avg_balance
from {{ ref('customers') }}
group by 1

) _q