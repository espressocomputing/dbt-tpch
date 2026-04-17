{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select order_key, count(*) as items
from {{ ref('td_tree10_mixed_root') }} group by 1
