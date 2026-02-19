{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:none', 'rows_sf1:180K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_oi_america_1994') }} limit 1)

select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount, oi.quantity
from {{ ref('oi_filter_high_value') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where r.region_name = 'AFRICA' and oi.order_date >= '1994-01-01' and oi.order_date <= '1994-12-31'

-- sf={{ var('sf', '10') }}
