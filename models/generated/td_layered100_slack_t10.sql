{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select count(*) as cnt, 'td_layered100_slack_t10' as _node
from {{ ref('td_layered100_slack_s05') }} a
cross join {{ ref('td_layered100_slack_s03') }} b
limit 50000
