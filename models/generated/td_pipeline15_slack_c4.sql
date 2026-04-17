{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select nation_count, nation_count + 1 as plus1 from {{ ref('td_pipeline15_slack_c3') }}
) _q