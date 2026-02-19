{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:860K', 'cols:10', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_recent') }} limit 1)

select
    order_item_key, order_key, order_date, customer_key,
    part_key, supplier_key, quantity, base_price,
    gross_item_sales_amount, net_item_sales_amount
from {{ ref('oi_filter_high_value') }}
where ship_mode_name = 'AIR'

-- sf={{ var('sf', '10') }}
