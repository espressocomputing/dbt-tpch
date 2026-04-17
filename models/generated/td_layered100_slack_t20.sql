{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select *, 'td_layered100_slack_t20' as _node from {{ ref('td_layered100_slack_s04') }} where rn <= 1000
) _q