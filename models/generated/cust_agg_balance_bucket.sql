{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:simple', 'rows_sf1:20', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_oi_1997_furniture_agg') }} limit 1)

select
    floor(customer_account_balance / 1000) * 1000 as group_key,
    count(*) as cnt
from {{ ref('customers') }}
group by 1

) _q