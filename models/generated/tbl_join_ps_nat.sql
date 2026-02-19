{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts_suppliers+nations', 'joins:1', 'agg:none', 'rows_sf1:800K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    ps.part_supplier_key, ps.part_key, ps.supplier_key,
    ps.supplier_cost_amount,
    n.nation_name
from {{ ref('parts_suppliers') }} ps
join {{ ref('nations') }} n on ps.nation_key = n.nation_key

) _q