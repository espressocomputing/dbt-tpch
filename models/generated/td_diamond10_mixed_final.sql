{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_diamond10_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select count(*) as total_rows
from {{ ref('td_diamond10_mixed_sink') }}
