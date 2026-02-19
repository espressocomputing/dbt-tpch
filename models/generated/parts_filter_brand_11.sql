{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:4K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    part_key, part_name, part_brand_name, part_type_name, part_size, retail_price
from {{ ref('parts') }}
where part_brand_name = 'Brand#11'

) _q