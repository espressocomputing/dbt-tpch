{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:15K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_oi_agg_part') }} limit 1)

select customer_key, customer_name, customer_account_balance
from {{ ref('customers') }}
where customer_account_balance > 9000

) _q