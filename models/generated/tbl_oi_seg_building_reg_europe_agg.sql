{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:simple', 'rows_sf1:7', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_asia_1993') }} limit 1)

select
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where c.customer_market_segment_name = 'BUILDING'
    and r.region_name = 'EUROPE'

{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}
group by 1

-- sf={{ var('sf', '10') }}
