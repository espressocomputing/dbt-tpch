{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:6M', 'cols:8', 'filter:none', 'sample', 'sf' ~ var('sf', '10')]
    )
}}

select
    order_item_key,
    order_date, ship_date, receipt_date,
    datediff(day, order_date, ship_date) as days_to_ship,
    datediff(day, ship_date, receipt_date) as days_in_transit,
    case
        when datediff(day, order_date, ship_date) <= 3 then 'express'
        when datediff(day, order_date, ship_date) <= 7 then 'standard'
        when datediff(day, order_date, ship_date) <= 14 then 'economy'
        else 'delayed'
    end as shipping_speed,
    gross_item_sales_amount
from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}
