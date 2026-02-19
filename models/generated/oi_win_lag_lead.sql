{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_recent') }} limit 1)

select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    lag(gross_item_sales_amount) over (partition by customer_key order by order_date) as prev_sales,
    lead(gross_item_sales_amount) over (partition by customer_key order by order_date) as next_sales
from {{ ref('oi_full_scan') }}

-- sf={{ var('sf', '10') }}
