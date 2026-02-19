{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:150K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select customer_key, customer_name, nation_key, customer_account_balance, customer_market_segment_name
from {{ ref('customers') }}

-- sf={{ var('sf', '10') }}
