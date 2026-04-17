{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select cnt, _node as src, 'td_layered100_slack_a07' as _node from {{ ref('td_layered100_slack_t17') }}
) _q