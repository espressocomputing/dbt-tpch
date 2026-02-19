{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:suppliers+nations', 'joins:1', 'agg:none', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('pt_brand_brand21') }} limit 1)

select
    s.supplier_key, s.supplier_name, s.supplier_account_balance,
    n.nation_name
from {{ ref('suppliers') }} s
join {{ ref('nations') }} n on s.nation_key = n.nation_key

-- sf={{ var('sf', '10') }}
