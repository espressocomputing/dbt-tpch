{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select count(*) as cnt, 'td_layered100_slack_t01' as _node
from {{ ref('td_layered100_slack_s03') }} a
cross join {{ ref('td_layered100_slack_s01') }} b
limit 50000
