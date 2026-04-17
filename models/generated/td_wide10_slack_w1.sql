{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select *, row_number() over (order by total_sales desc) as rank
from {{ ref('td_wide10_slack_src') }}
) _q