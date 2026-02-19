{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:50', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    part_key, part_name, part_brand_name, retail_price
from {{ ref('parts') }}
order by retail_price desc
limit 50

-- sf={{ var('sf', '10') }}
