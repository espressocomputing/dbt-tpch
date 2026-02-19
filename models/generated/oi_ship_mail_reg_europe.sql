{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:none', 'rows_sf1:170K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount
from {{ ref('tbl_oi_returned') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where oi.ship_mode_name = 'MAIL'
    and r.region_name = 'EUROPE'

-- sf={{ var('sf', '10') }}
