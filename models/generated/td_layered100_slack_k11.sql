{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select count(*) as final_cnt, 'td_layered100_slack_k11' as _node from {{ ref('td_layered100_slack_j08') }}
) _q