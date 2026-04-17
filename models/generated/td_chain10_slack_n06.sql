{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select *, row_count * 2 as doubled from {{ ref('td_chain10_slack_n05') }}
) _q