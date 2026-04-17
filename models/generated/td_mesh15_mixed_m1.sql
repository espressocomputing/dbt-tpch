{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select customer_key, sum(gross_item_sales_amount) as total
from {{ ref('td_mesh15_mixed_s1') }} group by 1
) _q