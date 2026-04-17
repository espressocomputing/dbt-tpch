{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select *, row_number() over (order by total desc) as rank
from {{ ref('td_pipeline15_slack_a3') }}
) _q