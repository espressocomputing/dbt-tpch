{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers+nations+regions', 'joins:2', 'agg:none', 'rows_sf1:150K', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    c.customer_account_balance,
    n.nation_name,
    r.region_name
from {{ ref('cust_seg_building') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key

-- sf={{ var('sf', '10') }}
