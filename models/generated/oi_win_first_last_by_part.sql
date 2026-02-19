{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_seg_automobile_reg_middle_east') }} limit 1)

select
    order_item_key, part_key as dim_key, order_date,
    gross_item_sales_amount,
    first_value(gross_item_sales_amount) over (partition by part_key order by order_date) as first_sale,
    last_value(gross_item_sales_amount) over (partition by part_key order by order_date rows between unbounded preceding and unbounded following) as last_sale
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
