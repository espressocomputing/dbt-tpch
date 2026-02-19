{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
where order_priority_code = '3-MEDIUM'
    and order_date >= '1994-01-01' and order_date <= '1994-12-31'
{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}

-- sf={{ var('sf', '10') }}
