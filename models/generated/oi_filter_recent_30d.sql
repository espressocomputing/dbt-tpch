{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:500K', 'cols:10', 'filter:medium', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_brand_brand35') }} limit 1)

select
    order_item_key, order_key, order_date, customer_key,
    part_key, supplier_key, quantity, base_price,
    gross_item_sales_amount, net_item_sales_amount
from {{ ref('oi_filter_rail_ship') }}
where ship_date >= dateadd(day, -30, '1998-12-01')

-- sf={{ var('sf', '10') }}
