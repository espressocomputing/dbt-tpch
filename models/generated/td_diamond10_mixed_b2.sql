{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_diamond10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select a.* from {{ ref('td_diamond10_mixed_a2') }} a
join {{ ref('td_diamond10_mixed_a3') }} b on a.customer_key = b.customer_key
) _q