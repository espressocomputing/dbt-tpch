{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:30K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('oi_brand_brand23_1993') }} limit 1)

select
    customer_key, customer_name, customer_account_balance, nation_key
from {{ ref('cust_full_scan') }}
where customer_market_segment_name = 'BUILDING'

) _q