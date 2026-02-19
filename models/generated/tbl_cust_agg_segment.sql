{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:simple', 'rows_sf1:5', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select customer_market_segment_name, count(*) as cnt, avg(customer_account_balance) as avg_balance
from {{ ref('customers') }}
group by customer_market_segment_name

-- sf={{ var('sf', '10') }}
