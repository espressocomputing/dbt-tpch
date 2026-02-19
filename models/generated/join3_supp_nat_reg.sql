{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:suppliers+nations+regions', 'joins:2', 'agg:none', 'rows_sf1:10K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    s.supplier_key, s.supplier_name, s.supplier_account_balance,
    n.nation_name, r.region_name
from {{ ref('supp_full_scan') }} s
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key

) _q