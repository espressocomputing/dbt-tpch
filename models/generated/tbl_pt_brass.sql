{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:25K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_ship_truck_reg_america') }} limit 1)

select part_key, part_name, part_type_name, retail_price
from {{ ref('parts') }}
where part_type_name like '%BRASS%'

-- sf={{ var('sf', '10') }}
