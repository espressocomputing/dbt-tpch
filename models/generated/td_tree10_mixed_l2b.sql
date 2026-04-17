{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select customer_key, total * 1.1 as adjusted from {{ ref('td_tree10_mixed_l1a') }}
) _q