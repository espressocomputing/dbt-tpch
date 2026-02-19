{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_brand_brand55') }} limit 1)

select
    order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
where order_priority_code = '1-URGENT'
    and order_date >= '1998-01-01' and order_date <= '1998-12-01'

-- sf={{ var('sf', '10') }}
