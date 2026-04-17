{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select count(*) as cnt, 'td_layered100_slack_t12' as _node from {{ ref('td_layered100_slack_s01') }}
) _q