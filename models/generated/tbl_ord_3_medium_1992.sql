{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_ship_reg_air_seg_furniture') }} limit 1)

select
    order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
where order_priority_code = '3-MEDIUM'
    and order_date >= '1992-01-01' and order_date <= '1992-12-31'

-- sf={{ var('sf', '10') }}
