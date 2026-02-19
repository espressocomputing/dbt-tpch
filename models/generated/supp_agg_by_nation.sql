{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:suppliers', 'joins:0', 'agg:simple', 'rows_sf1:25', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_cust_agg_segment') }} limit 1)

select
    nation_key as group_key,
    count(*) as cnt, avg(supplier_account_balance) as avg_balance
from {{ ref('suppliers') }}
group by 1

-- sf={{ var('sf', '10') }}
