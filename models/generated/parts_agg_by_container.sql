{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:simple', 'rows_sf1:40', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_date_1992') }} limit 1)

select
    part_container_desc as group_key,
    count(*) as cnt, avg(retail_price) as avg_price
from {{ ref('parts') }}
group by 1

-- sf={{ var('sf', '10') }}
