{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:simple', 'rows_sf1:25', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select part_brand_name, count(*) as cnt, avg(retail_price) as avg_price
from {{ ref('parts_full_scan') }}
group by part_brand_name

) _q