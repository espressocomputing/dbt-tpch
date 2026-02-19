{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:900K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    row_number() over (partition by customer_key order by gross_item_sales_amount desc) as sales_rank
from {{ ref('orders_items') }}
where order_date >= '1997-01-01' and order_date <= '1997-12-31'

-- sf={{ var('sf', '10') }}
