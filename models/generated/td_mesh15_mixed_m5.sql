{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select * from {{ ref('td_mesh15_mixed_s1') }} where gross_item_sales_amount > 5000
) _q