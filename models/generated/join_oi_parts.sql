{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts', 'joins:1', 'agg:none', 'rows_sf1:6M', 'cols:10', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_ord_2_high_1994') }} limit 1)

select
    oi.order_item_key, oi.order_date, oi.customer_key, oi.supplier_key,
    oi.quantity, oi.gross_item_sales_amount,
    p.part_name, p.part_brand_name, p.part_type_name, p.retail_price
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key

-- sf={{ var('sf', '10') }}
