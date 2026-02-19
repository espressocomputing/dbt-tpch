{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.ship_mode_name = 'SHIP'
    and c.customer_market_segment_name = 'AUTOMOBILE'

{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}
group by 1

-- sf={{ var('sf', '10') }}
