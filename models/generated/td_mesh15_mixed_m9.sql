{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select * from {{ ref('td_mesh15_mixed_m5') }} limit 10000
) _q