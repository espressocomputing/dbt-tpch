{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts_suppliers', 'joins:0', 'agg:simple', 'rows_sf1:25', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    nation_key as group_key,
    count(*) as cnt, avg(supplier_cost_amount) as avg_cost
from {{ ref('parts_suppliers') }}
group by 1

) _q