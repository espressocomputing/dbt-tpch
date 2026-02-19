{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers+nations', 'joins:1', 'agg:none', 'rows_sf1:150K', 'cols:2', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select distinct c.customer_key, n.nation_name
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key

-- sf={{ var('sf', '10') }}
