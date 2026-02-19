{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts_suppliers', 'joins:0', 'agg:simple', 'rows_sf1:200K', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select part_key, count(*) as supplier_count, avg(supplier_cost_amount) as avg_cost
from {{ ref('parts_suppliers') }}
group by part_key

-- sf={{ var('sf', '10') }}
