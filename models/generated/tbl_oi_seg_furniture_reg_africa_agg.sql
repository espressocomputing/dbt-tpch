{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:simple', 'rows_sf1:7', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('ord_filter_open') }} limit 1)

select
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where c.customer_market_segment_name = 'FURNITURE'
    and r.region_name = 'AFRICA'
group by 1

-- sf={{ var('sf', '10') }}
