{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select part_key, part_name, part_brand_name, part_type_name, part_size, retail_price,
       row_number() over (partition by part_key order by part_key) as rn
from {{ ref('parts') }}
