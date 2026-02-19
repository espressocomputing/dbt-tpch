{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    part_manufacturer_name as group_key,
    count(*) as cnt, avg(retail_price) as avg_price
from {{ ref('parts') }}
group by 1

-- sf={{ var('sf', '10') }}
