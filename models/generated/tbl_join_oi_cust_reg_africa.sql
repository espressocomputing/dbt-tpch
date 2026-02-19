{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:none', 'rows_sf1:1.2M', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    c.customer_name
from {{ ref('oi_full_scan') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where r.region_name = 'AFRICA'

-- sf={{ var('sf', '10') }}
