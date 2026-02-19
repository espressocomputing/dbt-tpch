{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts_suppliers', 'joins:0', 'agg:simple', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    supplier_key as group_key,
    count(*) as part_count, avg(supplier_cost_amount) as avg_cost, sum(supplier_availabe_quantity) as total_avail
from {{ ref('parts_suppliers') }}
group by 1

-- sf={{ var('sf', '10') }}
