{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:suppliers', 'joins:0', 'agg:simple', 'rows_sf1:25', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    nation_key as group_key,
    count(*) as cnt, avg(supplier_account_balance) as avg_balance
from {{ ref('suppliers') }}
group by 1

-- sf={{ var('sf', '10') }}
