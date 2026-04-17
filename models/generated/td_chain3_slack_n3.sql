{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain3_slack', 'sf' ~ var('sf', '10')]
    )
}}


select count(*) as total_rows
from {{ ref('td_chain3_slack_n2') }}
