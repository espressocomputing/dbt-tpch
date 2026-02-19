{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_item_key, supplier_key as dim_key, order_date,
    gross_item_sales_amount,
    first_value(gross_item_sales_amount) over (partition by supplier_key order by order_date) as first_sale,
    last_value(gross_item_sales_amount) over (partition by supplier_key order by order_date rows between unbounded preceding and unbounded following) as last_sale
from {{ ref('orders_items') }}

) _q