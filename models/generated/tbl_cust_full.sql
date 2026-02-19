{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:150K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('join_oi_cust_reg_middle_east') }} limit 1)

select customer_key, customer_name, nation_key, customer_account_balance, customer_market_segment_name
from {{ ref('customers') }}

) _q