{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:7', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select 'AIR' as ship_mode, count(*) as cnt, sum(gross_item_sales_amount) as total
from {{ ref('orders_items') }} where ship_mode_name = 'AIR'
union all
select 'RAIL', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'RAIL'
union all
select 'TRUCK', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'TRUCK'
union all
select 'SHIP', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'SHIP'
union all
select 'MAIL', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'MAIL'
union all
select 'REG AIR', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'REG AIR'
union all
select 'FOB', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'FOB'

-- sf={{ var('sf', '10') }}
