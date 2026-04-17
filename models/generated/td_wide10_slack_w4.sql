{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select customer_key, total_sales from {{ ref('td_wide10_slack_src') }} where line_count > 100
) _q