{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:30K', 'cols:6', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand13_1998') }} limit 1)

select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_amount
from {{ ref('ord_full_scan') }}
where order_amount > 400000

-- sf={{ var('sf', '10') }}
