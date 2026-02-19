{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:50', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    part_key, part_name, part_brand_name, retail_price
from {{ ref('parts') }}
order by retail_price desc
limit 50

) _q