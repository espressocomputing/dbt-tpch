{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:6M', 'cols:24', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key, order_key, order_date, customer_key, order_status_code,
    part_key, supplier_key, return_status_code, order_line_number,
    order_line_status_code, ship_date, commit_date, receipt_date,
    ship_mode_name, quantity, base_price, discount_percentage,
    discounted_price, gross_item_sales_amount, discounted_item_sales_amount,
    item_discount_amount, tax_rate, item_tax_amount, net_item_sales_amount
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
