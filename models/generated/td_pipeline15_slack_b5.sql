{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}


select count(*) as total_rows
from {{ ref('td_pipeline15_slack_b4') }}
