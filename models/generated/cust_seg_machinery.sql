{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:30K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_seg_automobile_reg_america') }} limit 1)

select
    customer_key, customer_name, customer_account_balance, nation_key
from {{ ref('cust_filter_high_balance') }}
where customer_market_segment_name = 'MACHINERY'

-- sf={{ var('sf', '10') }}
