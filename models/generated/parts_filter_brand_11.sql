{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:4K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_h2_1994_truck') }} limit 1)

select
    part_key, part_name, part_brand_name, part_type_name, part_size, retail_price
from {{ ref('tbl_pt_full') }}
where part_brand_name = 'Brand#11'

-- sf={{ var('sf', '10') }}
