{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select order_key, items * 2 as doubled from {{ ref('td_tree10_mixed_l1b') }}
) _q