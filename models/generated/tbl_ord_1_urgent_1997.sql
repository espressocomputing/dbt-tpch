{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('pt_brand_brand41') }} limit 1)

select
    order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
where order_priority_code = '1-URGENT'
    and order_date >= '1997-01-01' and order_date <= '1997-12-31'
{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}

-- sf={{ var('sf', '10') }}
