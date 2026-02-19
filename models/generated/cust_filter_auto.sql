{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:30K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    customer_key, customer_name, nation_key,
    customer_account_balance, customer_market_segment_name
from {{ ref('cust_full_scan') }}
where customer_market_segment_name = 'AUTOMOBILE'

-- sf={{ var('sf', '10') }}
