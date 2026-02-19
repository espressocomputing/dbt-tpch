{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:300K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_key, order_date, customer_key, order_amount
from {{ ref('ord_date_1993') }}
where order_priority_code = '5-LOW'

-- sf={{ var('sf', '10') }}
