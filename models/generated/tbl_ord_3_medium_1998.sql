{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('pt_brand_brand13') }} limit 1)

select
    order_key, order_date, customer_key, order_amount
from {{ ref('ord_date_1992') }}
where order_priority_code = '3-MEDIUM'
    and order_date >= '1998-01-01' and order_date <= '1998-12-01'

-- sf={{ var('sf', '10') }}
