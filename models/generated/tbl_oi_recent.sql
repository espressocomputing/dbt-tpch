{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:1.5M', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('join_oi_cust_reg_middle_east') }} limit 1)

select order_item_key, order_key, order_date, customer_key, quantity, gross_item_sales_amount
from {{ ref('tbl_oi_rail') }}
where ship_date >= dateadd(day, -90, '1998-12-01')

-- sf={{ var('sf', '10') }}
