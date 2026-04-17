{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select customer_key, count(*) as cnt from {{ ref('td_mesh15_mixed_s3') }} group by 1
) _q