{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select a.* from {{ ref('td_mesh15_mixed_m2') }} a
join {{ ref('td_mesh15_mixed_m3') }} b on a.customer_key = b.customer_key
) _q