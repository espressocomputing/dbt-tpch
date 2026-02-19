{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:220K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_1992_ship') }} limit 1)

select
    order_key, order_date, customer_key, order_status_code,
    order_amount
from {{ ref('orders') }}
where order_date >= '1994-01-01' and order_date <= '1994-06-30'

-- sf={{ var('sf', '10') }}
