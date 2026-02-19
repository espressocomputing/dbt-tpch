{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:7', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    ship_mode_name as group_key,
    count(*) as cnt, sum(quantity) as total_qty, avg(base_price) as avg_price, sum(net_item_sales_amount) as total_net
from {{ ref('oi_date_1994') }}
group by 1

-- sf={{ var('sf', '10') }}
