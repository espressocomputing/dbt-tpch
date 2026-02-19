{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:200K', 'cols:8', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_africa_1993') }} limit 1)

select
    part_key, part_name, part_manufacturer_name, part_brand_name,
    part_type_name, part_size, part_container_desc, retail_price
from {{ ref('parts') }}

-- sf={{ var('sf', '10') }}
