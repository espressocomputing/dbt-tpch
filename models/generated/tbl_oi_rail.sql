{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:860K', 'cols:6', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    order_item_key, order_key, order_date, customer_key,
    quantity, gross_item_sales_amount
from {{ ref('oi_full_scan') }}
where ship_mode_name = 'RAIL'
{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}

) _q