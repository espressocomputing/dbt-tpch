{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:200K', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_ord_prio_2_high_seg_household_agg') }} limit 1)

select part_key, part_name, part_brand_name, part_type_name, part_size, retail_price
from {{ ref('parts') }}

-- sf={{ var('sf', '10') }}
