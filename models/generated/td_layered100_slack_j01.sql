{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select a.cnt as cnt_a, a.src, 'td_layered100_slack_j01' as _node from {{ ref('td_layered100_slack_a18') }} a
cross join {{ ref('td_layered100_slack_a22') }} b
) _q