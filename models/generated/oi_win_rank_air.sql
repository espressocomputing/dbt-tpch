{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:1.5M', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    row_number() over (partition by customer_key order by gross_item_sales_amount desc) as sales_rank
from {{ ref('orders_items') }}
where ship_mode_name = 'AIR'

-- sf={{ var('sf', '10') }}
