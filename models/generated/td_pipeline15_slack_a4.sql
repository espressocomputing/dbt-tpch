{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}


select *, row_number() over (order by total desc) as rnk
from {{ ref('td_pipeline15_slack_a3') }}
