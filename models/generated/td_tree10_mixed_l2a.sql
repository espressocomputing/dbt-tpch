{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select * from {{ ref('td_tree10_mixed_l1a') }} where total > 10000
) _q