{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_1993_ship') }} limit 1)

select
    order_item_key, customer_key, gross_item_sales_amount,
    ntile(100) over (order by gross_item_sales_amount) as percentile_bucket,
    ntile(10) over (partition by customer_key order by gross_item_sales_amount) as decile_bucket
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
