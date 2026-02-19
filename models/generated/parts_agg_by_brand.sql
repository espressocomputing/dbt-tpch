{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:simple', 'rows_sf1:25', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    part_brand_name as group_key,
    count(*) as cnt, avg(retail_price) as avg_price, min(part_size) as min_size, max(part_size) as max_size
from {{ ref('parts') }}
group by 1

-- sf={{ var('sf', '10') }}
