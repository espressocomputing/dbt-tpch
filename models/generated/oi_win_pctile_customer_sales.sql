{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:window', 'rows_sf1:6M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_seg_automobile_reg_america') }} limit 1)

select
    order_item_key, customer_key as dim_key, gross_item_sales_amount as measure,
    percent_rank() over (partition by customer_key order by gross_item_sales_amount) as pct_rank,
    cume_dist() over (partition by customer_key order by gross_item_sales_amount) as cum_dist
from {{ ref('oi_full_scan') }}

-- sf={{ var('sf', '10') }}
