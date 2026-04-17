{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, row_number() over (order by total_sales desc) as rnk
from {{ ref('td_wide10_slack_src') }}
