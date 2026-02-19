{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:150K', 'cols:7', 'filter:none', 'sample', 'sf' ~ var('sf', '10')]
    )
}}

select
    customer_key, customer_name, customer_address, nation_key,
    customer_phone_number, customer_account_balance, customer_market_segment_name
from {{ ref('customers') }}

-- sf={{ var('sf', '10') }}
