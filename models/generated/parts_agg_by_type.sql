{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:simple', 'rows_sf1:150', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    part_type_name as group_key,
    count(*) as cnt, avg(retail_price) as avg_price
from {{ ref('parts') }}
group by 1

) _q