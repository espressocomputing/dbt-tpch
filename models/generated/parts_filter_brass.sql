{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:25K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_1997_furniture_agg') }} limit 1)

select
    part_key, part_name, part_brand_name, part_type_name, part_size, retail_price
from {{ ref('parts') }}
where part_type_name like '%BRASS%'

-- sf={{ var('sf', '10') }}
