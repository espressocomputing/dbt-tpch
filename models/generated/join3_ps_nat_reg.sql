{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts_suppliers+nations+regions', 'joins:2', 'agg:none', 'rows_sf1:800K', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('oi_brand_brand23_1995') }} limit 1)

select
    ps.part_supplier_key, ps.part_key, ps.supplier_key,
    ps.supplier_cost_amount,
    n.nation_name,
    r.region_name
from {{ ref('parts_suppliers') }} ps
join {{ ref('nations') }} n on ps.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key

) _q