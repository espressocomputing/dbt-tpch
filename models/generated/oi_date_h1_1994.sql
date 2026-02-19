{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:900K', 'cols:9', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_agg_supplier') }} limit 1)

select
    order_item_key, order_key, order_date, customer_key, part_key,
    supplier_key, quantity, gross_item_sales_amount, net_item_sales_amount
from {{ ref('orders_items') }}
where order_date >= '1994-01-01' and order_date <= '1994-06-30'

-- sf={{ var('sf', '10') }}
