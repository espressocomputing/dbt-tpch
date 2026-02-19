{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts_suppliers', 'joins:0', 'agg:none', 'rows_sf1:800K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select part_supplier_key, part_key, supplier_key, supplier_cost_amount, supplier_availabe_quantity
from {{ ref('parts_suppliers') }}

) _q