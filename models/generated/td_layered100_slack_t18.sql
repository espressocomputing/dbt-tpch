{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select *, 'td_layered100_slack_t18' as _node from {{ ref('td_layered100_slack_s05') }} limit 50000
) _q