{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:suppliers', 'joins:0', 'agg:simple', 'rows_sf1:25', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_cust_agg_segment') }} limit 1)

select
    nation_key as group_key,
    count(*) as cnt, avg(supplier_account_balance) as avg_balance
from {{ ref('suppliers') }}
group by 1

) _q