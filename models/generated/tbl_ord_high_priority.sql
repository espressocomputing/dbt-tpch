{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:600K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_agg_date_h1_1994') }} limit 1)

select order_key, order_date, customer_key, order_amount, order_priority_code
from {{ ref('orders') }}
where order_priority_code in ('1-URGENT', '2-HIGH')

-- sf={{ var('sf', '10') }}
