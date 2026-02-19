{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:5', 'filter:none', 'sample', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, order_date, gross_item_sales_amount,
    sum(gross_item_sales_amount) over (order by order_date rows unbounded preceding) as running_total,
    avg(gross_item_sales_amount) over (order by order_date rows between 99 preceding and current row) as moving_avg_100
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
