{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select a.cnt as cnt_a, a.src, 'td_layered100_slack_j18' as _node from {{ ref('td_layered100_slack_a20') }} a
cross join {{ ref('td_layered100_slack_a09') }} b
) _q