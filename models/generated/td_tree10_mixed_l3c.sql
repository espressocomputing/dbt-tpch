{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select count(*) as total_rows
from {{ ref('td_tree10_mixed_l2c') }}
