{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:750K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_ord_5_low_1993') }} limit 1)

select order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
where order_status_code = 'F'

-- sf={{ var('sf', '10') }}
