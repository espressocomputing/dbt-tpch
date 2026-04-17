{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select count(*) as total_rows, sum(total_sales) as grand_total
from {{ ref('td_mesh15_mixed_t1') }}
) _q