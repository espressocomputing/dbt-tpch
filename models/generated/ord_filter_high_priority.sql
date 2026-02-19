{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:600K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_amount
from {{ ref('orders') }}
where order_priority_code in ('1-URGENT', '2-HIGH')

-- sf={{ var('sf', '10') }}
