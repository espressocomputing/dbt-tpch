{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:300K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_join4_oi_cust_nat_reg') }} limit 1)

select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_amount
from {{ ref('orders') }}
where order_priority_code = '5-LOW'

-- sf={{ var('sf', '10') }}
