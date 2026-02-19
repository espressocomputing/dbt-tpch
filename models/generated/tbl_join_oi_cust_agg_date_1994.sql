{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items+customers', 'joins:1', 'agg:simple', 'rows_sf1:5', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('pt_brand_brand32') }} limit 1)

select
    c.customer_market_segment_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('case_discount_tier') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
where oi.order_date >= '1994-01-01' and oi.order_date <= '1994-12-31'

{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}
group by 1

-- sf={{ var('sf', '10') }}
