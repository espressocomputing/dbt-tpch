{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select nation_key, count(*) as cnt
from {{ ref('nations') }}
group by 1
