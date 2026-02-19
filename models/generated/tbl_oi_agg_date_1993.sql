{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:100K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    customer_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    sum(quantity) as total_qty
from {{ ref('orders_items') }}
where order_date >= '1993-01-01' and order_date <= '1993-12-31'

{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}
group by 1

-- sf={{ var('sf', '10') }}
