{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:suppliers+orders_items', 'joins:1', 'agg:simple', 'rows_sf1:5K', 'cols:2', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select s.supplier_key, s.supplier_name
from {{ ref('suppliers') }} s
where s.supplier_key in (
    select supplier_key from {{ ref('orders_items') }}
    group by 1 having count(*) > 1000
)

) _q