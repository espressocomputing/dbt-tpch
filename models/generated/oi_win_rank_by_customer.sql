{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:24', 'filter:none', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    row_number() over (partition by customer_key order by gross_item_sales_amount desc) as sales_rank,
    sum(gross_item_sales_amount) over (partition by customer_key) as customer_total
from {{ ref('orders_items') }}

) _q