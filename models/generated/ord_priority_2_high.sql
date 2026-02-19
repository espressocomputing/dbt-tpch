{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:300K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_1993_air') }} limit 1)

select
    order_key, order_date, customer_key, order_amount
from {{ ref('ord_full_scan') }}
where order_priority_code = '2-HIGH'

-- sf={{ var('sf', '10') }}
