{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:750K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_brand_brand41') }} limit 1)

select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_amount
from {{ ref('orders') }}
where order_status_code = 'O'

-- sf={{ var('sf', '10') }}
