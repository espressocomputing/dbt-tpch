{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select *, 'td_mesh15_mixed_m6' as _source from {{ ref('td_mesh15_mixed_m6') }}
union all
select *, 'td_mesh15_mixed_m7' as _source from {{ ref('td_mesh15_mixed_m7') }}
) _q