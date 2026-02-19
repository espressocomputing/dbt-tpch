{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:100', 'cols:6', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_ord_prio_5_low_seg_automobile_agg') }} limit 1)

select
    order_item_key, order_key, part_key, supplier_key,
    gross_item_sales_amount, quantity
from {{ ref('orders_items') }}
order by gross_item_sales_amount desc
limit 100

-- sf={{ var('sf', '10') }}
