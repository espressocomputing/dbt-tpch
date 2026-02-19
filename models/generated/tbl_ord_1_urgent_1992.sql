{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_h1_1993_reg_air') }} limit 1)

select
    order_key, order_date, customer_key, order_amount
from {{ ref('tbl_ord_full') }}
where order_priority_code = '1-URGENT'
    and order_date >= '1992-01-01' and order_date <= '1992-12-31'

-- sf={{ var('sf', '10') }}
