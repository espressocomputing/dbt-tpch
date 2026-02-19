{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:6M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_item_key,
    discount_percentage,
    case
        when discount_percentage = 0 then 'none'
        when discount_percentage <= 0.03 then 'low'
        when discount_percentage <= 0.06 then 'medium'
        when discount_percentage <= 0.08 then 'high'
        else 'very_high'
    end as discount_tier,
    gross_item_sales_amount,
    item_discount_amount
from {{ ref('orders_items') }}

) _q