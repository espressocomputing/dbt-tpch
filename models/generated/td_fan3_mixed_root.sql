{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_fan3_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    oi.customer_key,
    c.customer_name,
    c.nation_key,
    sum(oi.gross_item_sales_amount) as total_sales,
    count(*) as line_count,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
group by 1, 2, 3
) _q