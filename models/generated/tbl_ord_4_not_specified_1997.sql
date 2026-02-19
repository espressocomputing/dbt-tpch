{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_key, order_date, customer_key, order_amount
from {{ ref('ord_full_scan') }}
where order_priority_code = '4-NOT SPECIFIED'
    and order_date >= '1997-01-01' and order_date <= '1997-12-31'
{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}

) _q