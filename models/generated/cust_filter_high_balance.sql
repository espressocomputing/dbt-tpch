{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:15K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    customer_key, customer_name, nation_key,
    customer_account_balance, customer_market_segment_name
from {{ ref('customers') }}
where customer_account_balance > 9000

-- sf={{ var('sf', '10') }}
