{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_solo_light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select * from {{ ref('nations') }}
) _q