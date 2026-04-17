{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select nation_key, sum(total_sales) as nation_sales from {{ ref('td_wide10_slack_src') }} group by 1
) _q