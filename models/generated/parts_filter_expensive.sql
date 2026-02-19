{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:20K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    part_key, part_name, part_brand_name, part_type_name, part_size, retail_price
from {{ ref('parts_full_scan') }}
where retail_price > 1900

) _q