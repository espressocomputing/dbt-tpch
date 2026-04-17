{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select count(*) as total_rows
from {{ ref('td_mesh15_mixed_t1') }}
