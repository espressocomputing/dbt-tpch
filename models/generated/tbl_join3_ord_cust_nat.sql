{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders+customers+nations', 'joins:2', 'agg:none', 'rows_sf1:1.5M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name,
    n.nation_name
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
{% if is_incremental() %}
  where order_date > (select max(order_date) from {{ this }})
{% endif %}

-- sf={{ var('sf', '10') }}
