{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:30K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    customer_key, customer_name, customer_account_balance, nation_key
from {{ ref('customers') }}
where customer_market_segment_name = 'FURNITURE'

-- sf={{ var('sf', '10') }}
