{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:1.5M', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select order_item_key, order_key, customer_key, quantity, gross_item_sales_amount, return_status_code
from {{ ref('orders_items') }}
where return_status_code = 'R'

) _q