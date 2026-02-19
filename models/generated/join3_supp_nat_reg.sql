{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:suppliers+nations+regions', 'joins:2', 'agg:none', 'rows_sf1:10K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_1996_automobile_agg') }} limit 1)

select
    s.supplier_key, s.supplier_name, s.supplier_account_balance,
    n.nation_name, r.region_name
from {{ ref('suppliers') }} s
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key

-- sf={{ var('sf', '10') }}
