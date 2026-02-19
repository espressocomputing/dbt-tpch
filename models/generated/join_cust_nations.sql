{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers+nations', 'joins:1', 'agg:none', 'rows_sf1:150K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_h2_1997_fob') }} limit 1)

select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    c.customer_account_balance,
    n.nation_name
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key

-- sf={{ var('sf', '10') }}
