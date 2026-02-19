{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:1.5M', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select order_key, order_date, customer_key, order_status_code, order_priority_code, order_amount
from {{ ref('ord_full_scan') }}
{% if is_incremental() %}
  where order_date > (select max(order_date) from {{ this }})
{% endif %}

-- sf={{ var('sf', '10') }}
