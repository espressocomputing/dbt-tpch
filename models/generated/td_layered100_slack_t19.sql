{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select count(*) as cnt, 'td_layered100_slack_t19' as _node
from {{ ref('td_layered100_slack_s01') }} a
cross join {{ ref('td_layered100_slack_s04') }} b
limit 50000
) _q