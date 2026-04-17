{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select count(*) as cnt, 'td_layered100_slack_t03' as _node
from {{ ref('td_layered100_slack_s00') }} a
cross join {{ ref('td_layered100_slack_s04') }} b
limit 50000
) _q