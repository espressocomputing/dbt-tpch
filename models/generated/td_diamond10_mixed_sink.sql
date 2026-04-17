{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_diamond10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select 'td_diamond10_mixed_b1' as src, count(*) as n from {{ ref('td_diamond10_mixed_b1') }}
union all
select 'td_diamond10_mixed_b2' as src, count(*) as n from {{ ref('td_diamond10_mixed_b2') }}
union all
select 'td_diamond10_mixed_b3' as src, count(*) as n from {{ ref('td_diamond10_mixed_b3') }}
) _q