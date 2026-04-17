{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select a.*, 'td_layered100_slack_t00' as _node
from {{ ref('td_layered100_slack_s01') }} a
join {{ ref('td_layered100_slack_s05') }} b on 1=1
limit 50000
) _q