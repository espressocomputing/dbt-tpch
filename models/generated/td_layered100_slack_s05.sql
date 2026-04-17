{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select part_key, count(*) as cnt
from {{ ref('parts_suppliers') }}
group by 1
