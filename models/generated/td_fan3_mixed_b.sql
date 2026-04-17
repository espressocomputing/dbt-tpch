{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_fan3_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select count(*) as total_rows
from {{ ref('td_fan3_mixed_root') }}
) _q