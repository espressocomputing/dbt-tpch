{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts_suppliers+nations+regions', 'joins:2', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    r.region_name,
    count(*) as ps_count,
    avg(ps.supplier_cost_amount) as avg_cost,
    sum(ps.supplier_availabe_quantity) as total_avail
from {{ ref('parts_suppliers') }} ps
join {{ ref('nations') }} n on ps.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1

-- sf={{ var('sf', '10') }}
