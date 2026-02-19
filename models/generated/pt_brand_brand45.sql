{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:8K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand21_1994') }} limit 1)

select
    part_key, part_name, part_type_name, part_size, retail_price
from {{ ref('parts_full_scan') }}
where part_brand_name = 'Brand#45'

-- sf={{ var('sf', '10') }}
