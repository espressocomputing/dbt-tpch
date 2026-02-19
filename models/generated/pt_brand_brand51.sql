{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:8K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_ord_prio_4_not_specified_seg_building_agg') }} limit 1)

select
    part_key, part_name, part_type_name, part_size, retail_price
from {{ ref('parts') }}
where part_brand_name = 'Brand#51'

) _q