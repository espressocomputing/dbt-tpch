{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_fan3_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select *
from {{ ref('td_fan3_mixed_root') }}
where gross_item_sales_amount > 1000
  and discount_percentage < 0.1
) _q