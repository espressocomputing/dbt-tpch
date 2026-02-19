{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:none', 'rows_sf1:180K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount, oi.quantity
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where r.region_name = 'ASIA' and oi.order_date >= '1993-01-01' and oi.order_date <= '1993-12-31'
{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}

-- sf={{ var('sf', '10') }}
