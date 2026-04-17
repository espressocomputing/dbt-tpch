{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select a.cnt as cnt_a, a.src, 'td_layered100_slack_j12' as _node from {{ ref('td_layered100_slack_a21') }} a
cross join {{ ref('td_layered100_slack_a23') }} b
) _q