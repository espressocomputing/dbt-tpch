{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:8K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    part_key, part_name, part_type_name, part_size, retail_price
from {{ ref('parts') }}
where part_brand_name = 'Brand#41'

-- sf={{ var('sf', '10') }}
