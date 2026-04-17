{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select cnt, cnt + 1 as cnt_plus from {{ ref('td_chain10_slack_n08') }}
) _q