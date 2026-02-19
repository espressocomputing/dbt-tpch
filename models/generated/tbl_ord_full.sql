{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:1.5M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand23_1995') }} limit 1)

select order_key, order_date, customer_key, order_status_code, order_priority_code, order_amount
from {{ ref('orders') }}

-- sf={{ var('sf', '10') }}
