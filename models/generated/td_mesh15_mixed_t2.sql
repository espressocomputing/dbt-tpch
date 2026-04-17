{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select *, 'td_mesh15_mixed_m7' as _source from {{ ref('td_mesh15_mixed_m7') }}
union all
select *, 'td_mesh15_mixed_m8' as _source from {{ ref('td_mesh15_mixed_m8') }}
union all
select *, 'td_mesh15_mixed_m9' as _source from {{ ref('td_mesh15_mixed_m9') }}
) _q