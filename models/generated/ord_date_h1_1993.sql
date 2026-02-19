{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:220K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_key, order_date, customer_key, order_status_code,
    order_amount
from {{ ref('ord_date_1993') }}
where order_date >= '1993-01-01' and order_date <= '1993-06-30'

-- sf={{ var('sf', '10') }}
