{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts_suppliers', 'joins:0', 'agg:simple', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_oi_agg_month') }} limit 1)

select
    supplier_key as group_key,
    count(*) as part_count, avg(supplier_cost_amount) as avg_cost, sum(supplier_availabe_quantity) as total_avail
from {{ ref('ps_full_scan') }}
group by 1

) _q