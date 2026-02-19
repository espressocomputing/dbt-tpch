{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:none', 'rows_sf1:1.2M', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount, oi.discount_percentage
from {{ ref('tbl_oi_rail') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where c.customer_market_segment_name = 'FURNITURE'
{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}

-- sf={{ var('sf', '10') }}
