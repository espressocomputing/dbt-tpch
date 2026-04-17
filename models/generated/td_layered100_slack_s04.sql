{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select supplier_key, count(*) as cnt
from {{ ref('suppliers') }}
group by 1
